// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0;

import "@darwinia/contracts-utils/contracts/AccountId.sol";
import "@darwinia/contracts-utils/contracts/ScaleCodec.sol";
import "@darwinia/contracts-utils/contracts/Bytes.sol";
import "@darwinia/contracts-utils/contracts/Hash.sol";

import "./interfaces/IStateStorage.sol";
import "./types/CommonTypes.sol";
import "./types/PalletBridgeMessages.sol";

library SmartChainXLib {
    bytes public constant account_derivation_prefix =
        "pallet-bridge/account-derivation/account";

    event DispatchResult(bool success, bytes result);

    // Send message over lane by calling the `send_message` dispatch call on
    // the source chain which is identified by the `callIndex` param.
    function _sendMessage(
        address _srcDispatchPrecompileAddress,
        bytes2 _callIndex,
        bytes4 _laneId,
        uint256 _deliveryAndDispatchFee,
        bytes memory _message
    ) internal {
        // the pricision in contract is 18, and in pallet is 9, transform the fee value
        uint256 feeOfPalletPrecision = _deliveryAndDispatchFee / (10**9);

        // encode send_message call
        PalletBridgeMessages.SendMessageCall
            memory sendMessageCall = PalletBridgeMessages.SendMessageCall(
                _callIndex,
                _laneId,
                _message,
                uint128(feeOfPalletPrecision)
            );

        bytes memory sendMessageCallEncoded = PalletBridgeMessages
            .encodeSendMessageCall(sendMessageCall);

        // dispatch the send_message call
        _dispatch(
            _srcDispatchPrecompileAddress,
            sendMessageCallEncoded,
            "Dispatch send_message failed"
        );
    }

    // Build the scale encoded message for the target chain.
    function _buildMessage(
        uint32 _specVersion,
        uint64 _weight,
        bytes memory _call
    ) internal view returns (bytes memory) {
        CommonTypes.EnumItemWithAccountId memory origin = CommonTypes
            .EnumItemWithAccountId(
                2, // index in enum
                AccountId.fromAddress(address(this)) // UserApp contract address
            );

        CommonTypes.EnumItemWithNull memory dispatchFeePayment = CommonTypes
            .EnumItemWithNull(0);

        return
            CommonTypes.encodeMessage(
                CommonTypes.Message(
                    _specVersion,
                    _weight,
                    origin,
                    dispatchFeePayment,
                    _call
                )
            );
    }

    // Get market fee from state storage of the substrate chain
    function _marketFee(address _srcStoragePrecompileAddress, bytes32 _storageKey)
        internal
        view
        returns (uint256)
    {
        bytes memory data = _getStateStorage(
            _srcStoragePrecompileAddress,
            abi.encodePacked(_storageKey),
            "Get market fee failed"
        );

        CommonTypes.Relayer memory relayer = CommonTypes.getLastRelayerFromVec(
            data
        );
        return relayer.fee * 10**9;
    }

    // Get the latest nonce from state storage
    function _latestNonce(
        address _srcStoragePrecompileAddress,
        bytes32 _storageKey,
        bytes4 _laneId
    ) internal view returns (uint64) {
        // 1. Get `OutboundLaneData` from storage
        // Full storage key == storageKey + Blake2_128Concat(laneId)
        bytes memory hashedLaneId = Hash.blake2b128Concat(
            abi.encodePacked(_laneId)
        );
        bytes memory fullStorageKey = abi.encodePacked(
            _storageKey,
            hashedLaneId
        );

        // Do get data by calling state storage precompile
        bytes memory data = _getStateStorage(
            _srcStoragePrecompileAddress,
            fullStorageKey,
            "Get OutboundLaneData failed"
        );

        // 2. Decode `OutboundLaneData` and return the latest nonce
        CommonTypes.OutboundLaneData memory outboundLaneData = CommonTypes
            .decodeOutboundLaneData(data);
        return outboundLaneData.latestGeneratedNonce;
    }

    function _deriveAccountId(bytes4 _srcChainId, bytes32 _accountId)
        internal
        view
        returns (bytes32)
    {
        bytes memory prefixLength = ScaleCodec.encodeUintCompact(
            account_derivation_prefix.length
        );
        bytes memory data = abi.encodePacked(
            prefixLength,
            account_derivation_prefix,
            _srcChainId,
            _accountId
        );
        return Hash.blake2bHash(data);
    }

    function _revertIfFailed(
        bool _success,
        bytes memory _resultData,
        string memory _revertMsg
    ) internal pure {
        if (!_success) {
            if (_resultData.length > 0) {
                assembly {
                    let resultDataSize := mload(_resultData)
                    revert(add(32, _resultData), resultDataSize)
                }
            } else {
                revert(_revertMsg);
            }
        }
    }

    // dispatch pallet dispatch-call
    function _dispatch(
        address _srcDispatchPrecompileAddress,
        bytes memory _callEncoded,
        string memory _errMsg
    ) internal {
        // Dispatch the call
        (bool success, bytes memory data) = _srcDispatchPrecompileAddress.call(
            _callEncoded
        );
        _revertIfFailed(success, data, _errMsg);
    }

    // derive an address from remote(source chain) sender address
    // H160(sender on the sourc chain) > AccountId32 > derived AccountId32 > H160
    function _deriveSenderFromRemote(bytes4 _srcChainId, address _srcMessageSender)
        internal
        view
        returns (address)
    {
        // H160(sender on the sourc chain) > AccountId32
        bytes32 derivedSubstrateAddress = AccountId.deriveSubstrateAddress(
            _srcMessageSender
        );

        // AccountId32 > derived AccountId32
        bytes32 derivedAccountId = SmartChainXLib._deriveAccountId(
            _srcChainId,
            derivedSubstrateAddress
        );

        // derived AccountId32 > H160
        address result = AccountId.deriveEthereumAddress(derivedAccountId);

        return result;
    }

    // Get the last delivered nonce from the state storage of the target chain's inbound lane
    function _lastDeliveredNonce(
        address _tgtStoragePrecompileAddress,
        bytes32 _storageKey,
        bytes4 _inboundLaneId
    ) internal view returns (uint64) {
        // 1. Get `inboundLaneData` from storage
        // Full storage key == storageKey + Blake2_128Concat(laneId)
        bytes memory hashedLaneId = Hash.blake2b128Concat(
            abi.encodePacked(_inboundLaneId)
        );
        bytes memory fullStorageKey = abi.encodePacked(
            _storageKey,
            hashedLaneId
        );

        // Do get data by calling state storage precompile
        bytes memory data = _getStateStorage(
            _tgtStoragePrecompileAddress,
            fullStorageKey,
            "Get InboundLaneData failed"
        );

        // 2. Decode `InboundLaneData` and return the last delivered nonce
        return CommonTypes.getLastDeliveredNonceFromInboundLaneData(data);
    }

    function _getStateStorage(
        address _storagePrecompileAddress,
        bytes memory _storageKey,
        string memory _failedMsg
    ) internal view returns (bytes memory) {
        (bool success, bytes memory data) = _storagePrecompileAddress
            .staticcall(
                abi.encodeWithSelector(
                    IStateStorage.state_storage.selector,
                    _storageKey
                )
            );
        
        // TODO: Use try/catch instead for error
        _revertIfFailed(success, data, _failedMsg);

        return abi.decode(data, (bytes));
    }
}
