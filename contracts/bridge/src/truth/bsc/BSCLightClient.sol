// SPDX-License-Identifier: Apache-2.0
// # BSC(Binance Smart Chain) parlia light client
//
// The bsc parlia light client provides functionality for import finalized headers which submitted by
// relayer and import finalized authority set
//
// ## Overview
//
// The bsc-light-client provides functions for:
//
// - Import finalized bsc block header
// - Verify message storage proof from latest finalized block header
//
// ### Terminology
//
// - [`BSCHeader`]: The header structure of Binance Smart Chain.
//
// - `genesis_header` The initial header which set to this contract before it accepts the headers
//   submitted by relayers. We extract the initial authority set from this header and verify the
//   headers submitted later with the extracted initial authority set. So the genesis_header must
//   be verified manually.
//
// - `checkpoint` checkpoint is the block that fulfill block number % epoch_length == 0. This
//   concept comes from the implementation of Proof of Authority consensus algorithm
//
// ### Implementations
// If you want to review the code, you may need to read about Authority Round and Proof of
// Authority consensus algorithms first. Then you may look into the go implementation of bsc source
// code and probably focus on the consensus algorithm that bsc is using. Read the bsc official docs
// if you need them. For this pallet:
// The first thing you should care about is the configuration parameters of this pallet. Check the
// bsc official docs even the go source code to make sure you set them correctly
// In bsc explorer, choose a checkpoint block's header to set as the genesis header of this pallet.
// It's not important which block you take, but it's important that the relayers should submit
// headers from `genesis_header.number + epoch_length` Probably you need a tool to finish this,
// like POSTMAN For bsc testnet, you can access API https://data-seed-prebsc-1-s1.binance.org:8545 with
// following body input to get the header content.
// ```json
// {
//    "jsonrpc": "2.0",
//    "method": "eth_getBlockByNumber",
//    "params": [
//        "0x913640",
//        false
//    ],
//    "id": 83
// }
// ```
// According to the official doc of Binance Smart Chain, when the authority set changed at
// checkpoint header, the new authority set is not taken as finalized immediately.
// We will wait(accept and verify) N / 2 blocks(only headers) to make sure it's safe to finalize
// the new authority set. N is the authority set size.

pragma solidity 0.7.6;
pragma abicoder v2;

import "../common/StorageVerifier.sol";
import "../../utils/Bytes.sol";
import "../../utils/ECDSA.sol";
import "../../utils/EnumerableSet.sol";
import "../../spec/BinanceSmartChain.sol";
import "../../spec/ChainMessagePosition.sol";

contract BSCLightClient is BinanceSmartChain, StorageVerifier {
    using Bytes for bytes;
    using EnumerableSet for EnumerableSet.AddressSet;

    uint64 public immutable CHAIN_ID;
    uint64 public immutable PERIOD;

    uint64 constant private MIN_GAS_LIMIT = 5000;
    uint64 constant private MAX_GAS_LIMIT = 0x7fffffffffffffff;

    uint256 constant private EPOCH = 200;
    uint256 constant private DIFF_NOTURN = 1;
    uint256 constant private DIFF_INTURN = 2;
    uint256 constant private VANITY_LENGTH = 32;
    uint256 constant private ADDRESS_LENGTH = 20;
    uint256 constant private SIGNATURE_LENGTH = 65;
    bytes32 constant private KECCAK_EMPTY_LIST_RLP = 0x1dcc4de8dec75d7aab85b567b6ccd41ad312451b948a7413f0a142fd40d49347;

    struct StoredBlockHeader {
        bytes32 parent_hash;
        bytes32 state_root;
        bytes32 transactions_root;
        bytes32 receipts_root;
        uint256 number;
        uint256 timestamp;
        bytes32 hash;
    }

    // Finalized BSC checkpoint
    StoredBlockHeader public finalized_checkpoint;
    // Finalized BSC authorities
    EnumerableSet.AddressSet private _finalized_authorities;

    constructor(uint64 chain_id, uint64 period, BSCHeader memory header) StorageVerifier(uint32(ChainMessagePosition.BSC), 0, 1, 2) {
        address[] memory authorities = _extract_authorities(header.extra_data);
        _finalize_authority_set(authorities);
        bytes32 block_hash = hash(header);
        finalized_checkpoint = StoredBlockHeader({
            parent_hash: header.parent_hash,
            state_root: header.state_root,
            transactions_root: header.transactions_root,
            receipts_root: header.receipts_root,
            number: header.number,
            timestamp: header.timestamp,
            hash: block_hash
        });
        CHAIN_ID = chain_id;
        PERIOD = period;
    }

    function state_root() public view override returns (bytes32) {
        return finalized_checkpoint.state_root;
    }

    function finalized_authorities_contains(address value) public view returns (bool) {
        return _finalized_authorities.contains(value);
    }

    function length_of_finalized_authorities() public view returns (uint256) {
        return _finalized_authorities.length();
    }

    function finalized_authorities_at(uint256 index) public view returns (address) {
        return _finalized_authorities.at(index);
    }

    function finalized_authorities() public view returns (address[] memory) {
        return _finalized_authorities.values();
    }

    function import_finalized_epoch_header(BSCHeader[] calldata headers) external payable {
        // ensure valid length
        // we should submit `N/2 + 1` headers
        require(_finalized_authorities.length() / 2 + 1 == headers.length, "!headers_size");
        BSCHeader memory checkpoint = headers[0];

        // ensure valid header number
        // the first group headers that relayer submitted should exactly follow the initial
        // checkpoint eg. the initial header number is x, the first call of this extrinsic
        // should submit headers with numbers [x + epoch_length, x + epoch_length + 1, ...]
        require(finalized_checkpoint.number + EPOCH == checkpoint.number, "!number");
        // ensure first element is checkpoint block header
        require(checkpoint.number % EPOCH == 0, "!checkpoint");

        // verify checkpoint
        // basic checks
        contextless_checks(checkpoint);

        // check signer
        address signer0 = _recover_creator(checkpoint);
        require(_finalized_authorities.contains(signer0), "!signer0");

        _finalized_authorities.remove(signer0);

        // check already have `N/2` valid headers signed by different authority separately
        for (uint i = 1; i < headers.length; i++) {
            contextless_checks(headers[i]);
            // check parent
            contextual_checks(headers[i], headers[i-1]);

            // who signed this header
            address signerN = _recover_creator(headers[i]);
            require(_finalized_authorities.contains(signerN), "!signerN");
        }

        // clean old finalized_authorities
        _clean_finalized_authority_set();

        // extract new authority set from submitted checkpoint header
        address[] memory new_authority_set = _extract_authorities(checkpoint.extra_data);

        // do finalize new authority set
        _finalize_authority_set(new_authority_set);

        // do finalize new checkpoint
        finalized_checkpoint = StoredBlockHeader({
            parent_hash: checkpoint.parent_hash,
            state_root: checkpoint.state_root,
            transactions_root: checkpoint.transactions_root,
            receipts_root: checkpoint.receipts_root,
            number: checkpoint.number,
            timestamp: checkpoint.timestamp,
            hash: hash(checkpoint)
        });
    }

    function _clean_finalized_authority_set() internal {
        address[] memory v = _finalized_authorities.values();
        for (uint i = 0; i < v.length; i++) {
            _finalized_authorities.remove(v[i]);
        }
    }

    function _finalize_authority_set(address[] memory authorities) internal {
        for (uint i = 0; i < authorities.length; i++) {
            _finalized_authorities.add(authorities[i]);
        }
    }

    function contextless_checks(BSCHeader memory header) internal pure {
        // genesis block is always valid dead-end
        if (header.number == 0) return;

        // ensure nonce is empty
        require(header.nonce == 0, "!nonce");

        // gas limit check
        require(header.gas_limit >= MIN_GAS_LIMIT &&
                header.gas_limit <= MAX_GAS_LIMIT,
                "!gas_limit");

        // check gas used
        require(header.gas_used <= header.gas_limit, "!gas_used");

        // ensure block uncles are meaningless in PoA
        require(header.uncle_hash == KECCAK_EMPTY_LIST_RLP, "!uncle");

        // ensure difficulty is valid
        require(header.difficulty == DIFF_INTURN ||
                header.difficulty == DIFF_NOTURN,
                "!difficulty");

        // ensure block difficulty is meaningless (may bot be correct at this point)
        require(header.difficulty != 0, "!difficulty");

        // ensure mix digest is zero as we don't have fork pretection currently
        require(header.mix_digest == bytes32(0), "!mix_digest");

        // check extra-data contains vanity, validators and signature
        require(header.extra_data.length > VANITY_LENGTH, "!vanity");

        uint validator_bytes_len = sub(header.extra_data.length, VANITY_LENGTH + SIGNATURE_LENGTH);
        // ensure extra-data contains a validator list on checkpoint, but none otherwise
        bool is_checkpoint = header.number % EPOCH == 0;
        if (is_checkpoint) {
            // ensure blocks must at least contain one validator
            require(validator_bytes_len != 0, "!checkpoint_validators_size");
            // ensure validator bytes length is valid
            require(validator_bytes_len % ADDRESS_LENGTH == 0, "!checkpoint_validators_size");
        } else {
            require(validator_bytes_len == 0, "!validators_size");
        }
    }

    function contextual_checks(BSCHeader calldata header, BSCHeader calldata parent) internal view {
        // parent sanity check
        require(hash(parent) == header.parent_hash &&
                parent.number + 1 == header.number,
                "!ancestor");

        // ensure block's timestamp isn't too close to it's parent
        // and header. timestamp is greater than parents'
        require(header.timestamp >= add(parent.timestamp, PERIOD), "!timestamp");
    }

    function _recover_creator(BSCHeader memory header) internal view returns (address) {
        bytes memory extra_data = header.extra_data;

        require(extra_data.length > VANITY_LENGTH, "!vanity");
        require(extra_data.length >= VANITY_LENGTH + SIGNATURE_LENGTH, "!signature");

        // split `signed extra_data` and `signature`
        bytes memory signed_data = extra_data.substr(0, extra_data.length - SIGNATURE_LENGTH);
        bytes memory signature = extra_data.substr(extra_data.length - SIGNATURE_LENGTH, SIGNATURE_LENGTH);

        // modify header and hash it
        BSCHeader memory unsigned_header = BSCHeader({
            difficulty: header.difficulty,
            extra_data: signed_data,
            gas_limit: header.gas_limit,
            gas_used: header.gas_used,
            log_bloom: header.log_bloom,
            coinbase: header.coinbase,
            mix_digest: header.mix_digest,
            nonce: header.nonce,
            number: header.number,
            parent_hash: header.parent_hash,
            receipts_root: header.receipts_root,
            uncle_hash: header.uncle_hash,
            state_root: header.state_root,
            timestamp: header.timestamp,
            transactions_root: header.transactions_root
        });

        bytes32 message = hash_with_chain_id(unsigned_header, CHAIN_ID);
        require(signature.length == 65, "!signature");
        (bytes32 r, bytes32 vs) = extract_sign(signature);
        return ECDSA.recover(message, r, vs);
    }

    function extract_sign(bytes memory signature) internal pure returns(bytes32, bytes32) {
        bytes32 r;
        bytes32 s;
        uint8 v;
        assembly {
            r := mload(add(signature, 0x20))
            s := mload(add(signature, 0x40))
            v := byte(0, mload(add(signature, 0x60)))
        }
        bytes32 vs = (bytes32(uint(v)) << 255) | s;
        return (r, vs);
    }

    /// Extract authority set from extra_data.
    ///
    /// Layout of extra_data:
    /// ----
    /// VANITY: 32 bytes
    /// Signers: N * 32 bytes as hex encoded (20 characters)
    /// Signature: 65 bytes
    /// --
    function _extract_authorities(bytes memory extra_data) internal pure returns (address[] memory) {
        uint len = extra_data.length;
        require(len > VANITY_LENGTH + SIGNATURE_LENGTH, "!signer");
        bytes memory signers_raw = extra_data.substr(VANITY_LENGTH, len - VANITY_LENGTH - SIGNATURE_LENGTH);
        require(signers_raw.length % ADDRESS_LENGTH == 0, "!signers");
        uint num_signers = signers_raw.length / ADDRESS_LENGTH;
        address[] memory signers = new address[](num_signers);
        for (uint i = 0; i < num_signers; i++) {
            signers[i] = bytesToAddress(signers_raw.substr(i * ADDRESS_LENGTH, ADDRESS_LENGTH));
        }
        return signers;
    }

    function bytesToAddress(bytes memory bys) internal pure returns (address addr) {
        assembly {
          addr := mload(add(bys,20))
        }
    }

    function add(uint x, uint y) internal pure returns (uint z) {
        require((z = x + y) >= x);
    }
    function sub(uint x, uint y) internal pure returns (uint z) {
        require((z = x - y) <= x);
    }
}

