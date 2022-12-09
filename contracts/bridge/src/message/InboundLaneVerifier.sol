// This file is part of Darwinia.
// Copyright (C) 2018-2022 Darwinia Network
// SPDX-License-Identifier: GPL-3.0
//
// Darwinia is free software: you can redistribute it and/or modify
// it under the terms of the GNU General Public License as published by
// the Free Software Foundation, either version 3 of the License, or
// (at your option) any later version.
//
// Darwinia is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
// GNU General Public License for more details.
//
// You should have received a copy of the GNU General Public License
// along with Darwinia. If not, see <https://www.gnu.org/licenses/>.

pragma solidity 0.7.6;
pragma abicoder v2;

import "../interfaces/IVerifier.sol";
import "./LaneIdentity.sol";

contract InboundLaneVerifier is LaneIdentity {
    /// @dev The contract address of on-chain verifier
    IVerifier public immutable VERIFIER;

    constructor(
        address _verifier,
        uint32 _thisChainPosition,
        uint32 _thisLanePosition,
        uint32 _bridgedChainPosition,
        uint32 _bridgedLanePosition
    ) LaneIdentity(
        _thisChainPosition,
        _thisLanePosition,
        _bridgedChainPosition,
        _bridgedLanePosition
    ) {
        VERIFIER = IVerifier(_verifier);
    }

    function _verify_messages_proof(
        bytes32 outlane_data_hash,
        bytes memory encoded_proof
    ) internal view {
        Slot0 memory _slot0 = slot0;
        require(
            VERIFIER.verify_messages_proof(
                outlane_data_hash,
                _slot0.this_chain_pos,
                _slot0.bridged_lane_pos,
                encoded_proof
            ), "!proof"
        );
    }

    /// 32 bytes to identify an unique message from source chain
    /// MessageKey encoding:
    /// BridgedChainPosition | BridgedLanePosition | ThisChainPosition | ThisLanePosition | Nonce
    /// [0..8)   bytes ---- Reserved
    /// [8..12)  bytes ---- BridgedChainPosition
    /// [16..20) bytes ---- BridgedLanePosition
    /// [12..16) bytes ---- ThisChainPosition
    /// [20..24) bytes ---- ThisLanePosition
    /// [24..32) bytes ---- Nonce, max of nonce is `uint64(-1)`
    function encodeMessageKey(uint64 nonce) public view override returns (uint256) {
        Slot0 memory _slot0 = slot0;
        return (uint256(_slot0.bridged_chain_pos) << 160) +
                (uint256(_slot0.bridged_lane_pos) << 128) +
                (uint256(_slot0.this_chain_pos) << 96) +
                (uint256(_slot0.this_lane_pos) << 64) +
                uint256(nonce);
    }
}
