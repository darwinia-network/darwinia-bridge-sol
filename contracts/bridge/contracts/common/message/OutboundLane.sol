// SPDX-License-Identifier: MIT
// Message module that allows sending and receiving messages using lane concept:
//
// 1) the message is sent using `send_message()` call;
// 2) every outbound message is assigned nonce;
// 3) the messages are stored in the storage;
// 4) external component (relay) delivers messages to bridged chain;
// 5) messages are processed in order (ordered by assigned nonce);
// 6) relay may send proof-of-delivery back to this chain.
//
// Once message is sent, its progress can be tracked by looking at lane contract events.
// The assigned nonce is reported using `MessageAccepted` event. When message is
// delivered to the the bridged chain, it is reported using `MessagesDelivered` event.

pragma solidity ^0.8.0;
pragma abicoder v2;

import "../../interfaces/IOutboundLane.sol";
import "../../interfaces/IOnMessageDelivered.sol";
import "../../interfaces/IFeeMarket.sol";
import "./MessageVerifier.sol";
import "../spec/SourceChain.sol";
import "../spec/TargetChain.sol";

// Everything about outgoing messages sending.
contract OutboundLane is IOutboundLane, MessageVerifier, TargetChain, SourceChain {
    event MessageAccepted(uint64 indexed nonce, bytes encoded);
    event MessagesDelivered(uint64 indexed begin, uint64 indexed end, uint256 results);
    event MessagePruned(uint64 indexed oldest_unpruned_nonce);
    event MessageFeeIncreased(uint64 indexed nonce, uint256 fee);
    event CallbackMessageDelivered(uint64 indexed nonce, bool result);
    event Rely(address indexed usr);
    event Deny(address indexed usr);

    uint256 internal constant MAX_GAS_PER_MESSAGE = 100000;
    uint256 internal constant MAX_CALLDATA_LENGTH = 4096;
    uint64 internal constant MAX_PENDING_MESSAGES = 30;
    uint64 internal constant MAX_PRUNE_MESSAGES_ATONCE = 5;

    // Outbound lane nonce.
    struct OutboundLaneNonce {
        // Nonce of the latest message, received by bridged chain.
        uint64 latest_received_nonce;
        // Nonce of the latest message, generated by us.
        uint64 latest_generated_nonce;
        // Nonce of the oldest message that we haven't yet pruned. May point to not-yet-generated
        // message if all sent messages are already pruned.
        uint64 oldest_unpruned_nonce;
    }

    /* State */

    // slot 2
    OutboundLaneNonce public outboundLaneNonce;

    // slot 3
    // nonce => MessagePayload
    mapping(uint64 => MessagePayload) public messages;

    // white list who can send meesage over lane, will remove in the future
    mapping (address => uint256) public wards;
    address public fee_market;
    address public setter;

    uint256 internal locked;
    // --- Synchronization ---
    modifier nonReentrant {
        require(locked == 0, "Lane: locked");
        locked = 1;
        _;
        locked = 0;
    }

    modifier auth {
        require(wards[msg.sender] == 1, "Lane: NotAuthorized");
        _;
    }

    modifier onlySetter {
        require(msg.sender == setter, "Lane: NotAuthorized");
        _;
    }

    /**
     * @notice Deploys the OutboundLane contract
     * @param _lightClientBridge The contract address of on-chain light client
     * @param _thisChainPosition The thisChainPosition of outbound lane
     * @param _thisLanePosition The lanePosition of this outbound lane
     * @param _bridgedChainPosition The bridgedChainPosition of outbound lane
     * @param _bridgedLanePosition The lanePosition of target inbound lane
     * @param _oldest_unpruned_nonce The oldest_unpruned_nonce of outbound lane
     * @param _latest_received_nonce The latest_received_nonce of outbound lane
     * @param _latest_generated_nonce The latest_generated_nonce of outbound lane
     */
    constructor(
        address _lightClientBridge,
        uint32 _thisChainPosition,
        uint32 _thisLanePosition,
        uint32 _bridgedChainPosition,
        uint32 _bridgedLanePosition,
        uint64 _oldest_unpruned_nonce,
        uint64 _latest_received_nonce,
        uint64 _latest_generated_nonce
    ) MessageVerifier(_lightClientBridge, _thisChainPosition, _thisLanePosition, _bridgedChainPosition, _bridgedLanePosition) {
        outboundLaneNonce = OutboundLaneNonce(_latest_received_nonce, _latest_generated_nonce, _oldest_unpruned_nonce);
        setter = msg.sender;
    }

    function rely(address usr) external onlySetter nonReentrant { wards[usr] = 1; emit Rely(usr); }
    function deny(address usr) external onlySetter nonReentrant { wards[usr] = 0; emit Deny(usr); }

    function setFeeMarket(address _fee_market) external onlySetter nonReentrant {
        fee_market = _fee_market;
    }

    function changeSetter(address _setter) external onlySetter nonReentrant {
        setter = _setter;
    }

    /**
     * @notice Send message over lane.
     * Submitter could be a contract or just an EOA address.
     * At the beginning of the launch, submmiter is permission, after the system is stable it will be permissionless.
     * @param targetContract The target contract address which you would send cross chain message to
     * @param encoded The calldata which encoded by ABI Encoding
     */
    function send_message(address targetContract, bytes calldata encoded) external payable override auth nonReentrant returns (uint256) {
        require(outboundLaneNonce.latest_generated_nonce - outboundLaneNonce.latest_received_nonce <= MAX_PENDING_MESSAGES, "Lane: TooManyPendingMessages");
        require(outboundLaneNonce.latest_generated_nonce < type(uint64).max, "Lane: Overflow");
        uint64 nonce = outboundLaneNonce.latest_generated_nonce + 1;
        uint256 fee = msg.value;
        // assign the message to top relayers
        require(IFeeMarket(fee_market).assign{value: fee}(encodeMessageKey(nonce)), "Lane: AssignRelayersFailed");
        require(encoded.length <= MAX_CALLDATA_LENGTH, "Lane: Calldata is too large");
        outboundLaneNonce.latest_generated_nonce = nonce;
        messages[nonce] = MessagePayload({
            sourceAccount: msg.sender,
            targetContract: targetContract,
            encodedHash: keccak256(encoded)
        });

        // message sender prune at most `MAX_PRUNE_MESSAGES_ATONCE` messages
        prune_messages(MAX_PRUNE_MESSAGES_ATONCE);
        emit MessageAccepted(nonce, encoded);
        return encodeMessageKey(nonce);
    }

    // Receive messages delivery proof from bridged chain.
    function receive_messages_delivery_proof(
        InboundLaneData memory inboundLaneData,
        bytes memory messagesProof
    ) public nonReentrant {
        verify_messages_delivery_proof(hash(inboundLaneData), messagesProof);
        DeliveredMessages memory confirmed_messages = confirm_delivery(inboundLaneData);
        on_messages_delivered(confirmed_messages);
        // settle the confirmed_messages at fee market
        settle_messages(inboundLaneData.relayers, confirmed_messages.begin, confirmed_messages.end);
    }

    function message_size() public view returns (uint64 size) {
        size = outboundLaneNonce.latest_generated_nonce - outboundLaneNonce.latest_received_nonce;
    }

	// Get lane data from the storage.
    function data() public view returns (OutboundLaneData memory lane_data) {
        uint64 size = message_size();
        if (size > 0) {
            lane_data.messages = new Message[](size);
            uint64 begin = outboundLaneNonce.latest_received_nonce + 1;
            for (uint64 index = 0; index < size; index++) {
                uint64 nonce = index + begin;
                lane_data.messages[index] = Message(encodeMessageKey(nonce), messages[nonce]);
            }
        }
        lane_data.latest_received_nonce = outboundLaneNonce.latest_received_nonce;
    }

    // commit lane data to the `commitment` storage.
    function commitment() external view returns (bytes32) {
        return hash(data());
    }

    /* Private Functions */

    function extract_inbound_lane_info(InboundLaneData memory lane_data) internal pure returns (uint64 total_unrewarded_messages, uint64 last_delivered_nonce) {
        total_unrewarded_messages = lane_data.last_delivered_nonce - lane_data.last_confirmed_nonce;
        last_delivered_nonce = lane_data.last_delivered_nonce;
    }

    // Confirm messages delivery.
    function confirm_delivery(InboundLaneData memory inboundLaneData) internal returns (DeliveredMessages memory confirmed_messages) {
        (uint64 total_messages, uint64 latest_delivered_nonce) = extract_inbound_lane_info(inboundLaneData);
        require(total_messages < 256, "Lane: InvalidNumberOfMessages");

        UnrewardedRelayer[] memory relayers = inboundLaneData.relayers;
        OutboundLaneNonce memory nonce = outboundLaneNonce;
        require(latest_delivered_nonce > nonce.latest_received_nonce, "Lane: NoNewConfirmations");
        require(latest_delivered_nonce <= nonce.latest_generated_nonce, "Lane: FailedToConfirmFutureMessages");
        // that the relayer has declared correct number of messages that the proof contains (it
        // is checked outside of the function). But it may happen (but only if this/bridged
        // chain storage is corrupted, though) that the actual number of confirmed messages if
        // larger than declared.
        require(latest_delivered_nonce - nonce.latest_received_nonce <= total_messages, "Lane: TryingToConfirmMoreMessagesThanExpected");
        uint256 dispatch_results = extract_dispatch_results(nonce.latest_received_nonce, latest_delivered_nonce, relayers);
        uint64 prev_latest_received_nonce = nonce.latest_received_nonce;
        outboundLaneNonce.latest_received_nonce = latest_delivered_nonce;
        confirmed_messages = DeliveredMessages({
            begin: prev_latest_received_nonce + 1,
            end: latest_delivered_nonce,
            dispatch_results: dispatch_results
        });
        // emit 'MessagesDelivered' event
        emit MessagesDelivered(confirmed_messages.begin, confirmed_messages.end, confirmed_messages.dispatch_results);
    }

    // Extract new dispatch results from the unrewarded relayers vec.
    //
    // Revert if unrewarded relayers vec contains invalid data, meaning that the bridged
    // chain has invalid runtime storage.
    function extract_dispatch_results(uint64 prev_latest_received_nonce, uint64 latest_received_nonce, UnrewardedRelayer[] memory relayers) internal pure returns(uint256 received_dispatch_result) {
        // the only caller of this functions checks that the
        // prev_latest_received_nonce..=latest_received_nonce is valid, so we're ready to accept
        // messages in this range => with_capacity call must succeed here or we'll be unable to receive
        // confirmations at all
        uint64 last_entry_end = 0;
        uint64 padding = 0;
        for (uint64 i = 0; i < relayers.length; i++) {
            UnrewardedRelayer memory entry = relayers[i];
            // unrewarded relayer entry must have at least 1 unconfirmed message
            // (guaranteed by the `InboundLane::receive_message()`)
            require(entry.messages.end >= entry.messages.begin, "Lane: EmptyUnrewardedRelayerEntry");
            if (last_entry_end > 0) {
                uint64 expected_entry_begin = last_entry_end + 1;
                // every entry must confirm range of messages that follows previous entry range
                // (guaranteed by the `InboundLane::receive_message()`)
                require(entry.messages.begin == expected_entry_begin, "Lane: NonConsecutiveUnrewardedRelayerEntries");
            }
            last_entry_end = entry.messages.end;
            // entry can't confirm messages larger than `inbound_lane_data.latest_received_nonce()`
            // (guaranteed by the `InboundLane::receive_message()`)
			// technically this will be detected in the next loop iteration as
			// `InvalidNumberOfDispatchResults` but to guarantee safety of loop operations below
			// this is detected now
            require(entry.messages.end <= latest_received_nonce, "Lane: FailedToConfirmFutureMessages");
            // now we know that the entry is valid
            // => let's check if it brings new confirmations
            uint64 new_messages_begin = max(entry.messages.begin, prev_latest_received_nonce + 1);
            uint64 new_messages_end = min(entry.messages.end, latest_received_nonce);
            if (new_messages_end < new_messages_begin) {
                continue;
            }
            uint64 extend_begin = new_messages_begin - entry.messages.begin;
            uint256 hight_bits_opp = 255 - (new_messages_end - entry.messages.begin);
            // entry must have single dispatch result for every message
            // (guaranteed by the `InboundLane::receive_message()`)
            uint256 dispatch_results = (entry.messages.dispatch_results << hight_bits_opp) >> hight_bits_opp;
            // now we know that entry brings new confirmations
            // => let's extract dispatch results
            received_dispatch_result |= ((dispatch_results >> extend_begin) << padding);
            padding += (new_messages_end - new_messages_begin + 1 - extend_begin);
        }
    }

    function on_messages_delivered(DeliveredMessages memory confirmed_messages) internal {
        for (uint64 nonce = confirmed_messages.begin; nonce <= confirmed_messages.end; nonce ++) {
            uint256 offset = nonce - confirmed_messages.begin;
            bool dispatch_result = ((confirmed_messages.dispatch_results >> offset) & 1) > 0;
            // Submitter could be a contract or just an EOA address.
            address submitter = messages[nonce].sourceAccount;
            bytes memory deliveredCallbackData = abi.encodeWithSelector(
                IOnMessageDelivered.on_messages_delivered.selector,
                encodeMessageKey(nonce),
                dispatch_result
            );
            (bool ok,) = submitter.call{value: 0, gas: MAX_GAS_PER_MESSAGE}(deliveredCallbackData);
            emit CallbackMessageDelivered(nonce, ok);
        }
    }

    // Prune at most `max_messages_to_prune` already received messages.
    //
    // Returns number of pruned messages.
    function prune_messages(uint64 max_messages_to_prune) internal returns (uint64) {
        uint64 pruned_messages = 0;
        bool anything_changed = false;
        OutboundLaneNonce memory nonce = outboundLaneNonce;
        while (pruned_messages < max_messages_to_prune &&
            nonce.oldest_unpruned_nonce <= nonce.latest_received_nonce)
        {
            delete messages[nonce.oldest_unpruned_nonce];
            anything_changed = true;
            pruned_messages += 1;
            nonce.oldest_unpruned_nonce += 1;
        }
        if (anything_changed) {
            outboundLaneNonce = nonce;
            emit MessagePruned(outboundLaneNonce.oldest_unpruned_nonce);
        }
        return pruned_messages;
    }

    function settle_messages(UnrewardedRelayer[] memory relayers, uint64 received_start, uint64 received_end) internal {
        IFeeMarket.DeliveredRelayer[] memory delivery_relayers = new IFeeMarket.DeliveredRelayer[](relayers.length);
        for (uint256 i = 0; i < relayers.length; i++) {
            UnrewardedRelayer memory r = relayers[i];
            uint64 nonce_begin = max(r.messages.begin, received_start);
            uint64 nonce_end = min(r.messages.end, received_end);
            delivery_relayers[i] = IFeeMarket.DeliveredRelayer(r.relayer, encodeMessageKey(nonce_begin), encodeMessageKey(nonce_end));
        }
        require(IFeeMarket(fee_market).settle(delivery_relayers, msg.sender), "Lane: SettleFailed");
    }

    // --- Math ---
    function min(uint64 x, uint64 y) internal pure returns (uint64 z) {
        return x <= y ? x : y;
    }

    function max(uint64 x, uint64 y) internal pure returns (uint64 z) {
        return x >= y ? x : y;
    }
}
