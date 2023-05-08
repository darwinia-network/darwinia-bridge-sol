// hevm: flattened sources of src/truth/darwinia/ChainMessageCommitter.sol
// SPDX-License-Identifier: GPL-3.0
pragma solidity =0.8.17;

////// src/spec/MessageProof.sol
// This file is part of Darwinia.
// Copyright (C) 2018-2022 Darwinia Network
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

/* pragma solidity 0.8.17; */

/// @notice MessageProof
/// @param chainProof Chain message single proof
/// @param laneProof Lane message single proof
struct MessageProof {
    MessageSingleProof chainProof;
    MessageSingleProof laneProof;
}

/// @notice MessageSingleProof
/// @param root Merkle root
/// @param proof Merkle proof
struct MessageSingleProof {
    bytes32 root;
    bytes32[] proof;
}

////// src/interfaces/IMessageCommitter.sol
// This file is part of Darwinia.
// Copyright (C) 2018-2022 Darwinia Network
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

/* pragma solidity 0.8.17; */

/* import "../spec/MessageProof.sol"; */

/// @title IMessageCommitter
/// @notice A interface for message committer
interface IMessageCommitter {
    /// @notice Return leave count
    function count() external view returns (uint256);
    /// @notice Return pos leave proof
    /// @param pos Which position leave to be prove
    /// @return MessageSingleProof message single proof of the leave
    function proof(uint256 pos) external view returns (MessageSingleProof memory);
    /// @notice Return committer address of positon
    /// @param pos Which positon of all leaves
    /// @return committer address of the positon
    function leaveOf(uint256 pos) external view returns (address);
    /// @notice Return message commitment of the committer
    /// @return commitment hash
    function commitment() external view returns (bytes32);

    /// @notice this chain position
    function THIS_CHAIN_POSITION() external view returns (uint32);
    /// @notice bridged chain position
    function BRIDGED_CHAIN_POSITION() external view returns (uint32);
}

////// src/utils/Math.sol
// This file is part of Darwinia.
// Copyright (C) 2018-2022 Darwinia Network
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

/* pragma solidity 0.8.17; */

contract Math {
    /// Get the power of 2 for given input, or the closest higher power of 2 if the input is not a power of 2.
    /// Commonly used for "how many nodes do I need for a bottom tree layer fitting x elements?"
    /// Example: 0->1, 1->1, 2->2, 3->4, 4->4, 5->8, 6->8, 7->8, 8->8, 9->16.
    function get_power_of_two_ceil(uint256 x) internal pure returns (uint256) {
        if (x <= 1) return 1;
        else if (x == 2) return 2;
        else return 2 * get_power_of_two_ceil((x + 1) >> 1);
    }

    function log_2(uint256 x) internal pure returns (uint256 pow) {
        require(0 < x && x < 0x8000000000000000000000000000000000000000000000000000000000000001, "invalid");
        uint256 a = 1;
        while (a < x) {
            a <<= 1;
            pow++;
        }
    }
}

////// src/truth/common/MessageCommitter.sol
// This file is part of Darwinia.
// Copyright (C) 2018-2022 Darwinia Network
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

/* pragma solidity 0.8.17; */

/* import "../../utils/Math.sol"; */
/* import "../../spec/MessageProof.sol"; */
/* import "../../interfaces/IMessageCommitter.sol"; */

abstract contract MessageCommitter is Math {
    function count() public view virtual returns (uint256);
    function leaveOf(uint256 pos) public view virtual returns (address);

    /// @dev Get the commitment of all leaves
    /// @notice Return bytes(0) if there is no leave
    /// @return Commitment of this committer
    function commitment() public view returns (bytes32) {
        bytes32[] memory hashes = new bytes32[](get_power_of_two_ceil(count()));
        unchecked {
            for (uint256 pos = 0; pos < count(); pos++) {
                hashes[pos] = commitment(pos);
            }
            uint256 hashLength = hashes.length;
            for (uint256 j = 0; hashLength > 1; j = 0) {
                for (uint256 i = 0; i < hashLength; i = i + 2) {
                    hashes[j] = hash_node(hashes[i], hashes[i + 1]);
                    j = j + 1;
                }
                hashLength = hashLength - j;
            }
        }
        return hashes[0];
    }

    /// @dev Get the commitment of the leaf
    /// @notice Return bytes(0) if the leaf address is address(0)
    /// @param pos Positon of the leaf
    /// @return Commitment of the leaf
    function commitment(uint256 pos) public view returns (bytes32) {
        address leaf = leaveOf(pos);
        if (leaf == address(0)) {
            return bytes32(0);
        } else {
            return IMessageCommitter(leaf).commitment();
        }
    }
    /// @dev Construct a Merkle Proof for leave given by position.
    function proof(uint256 pos) public view returns (MessageSingleProof memory) {
        bytes32[] memory tree = merkle_tree();
        uint depth = log_2(get_power_of_two_ceil(count()));
        require(pos < count(), "!pos");
        return MessageSingleProof({
            root: root(tree),
            proof: get_proof(tree, depth, pos)
        });
    }

    function root(bytes32[] memory tree) public pure returns (bytes32) {
        require(tree.length > 1, "!tree");
        return tree[1];
    }

    function merkle_tree() public view returns (bytes32[] memory) {
        uint num_leafs = get_power_of_two_ceil(count());
        uint num_nodes = 2 * num_leafs;
        uint depth = log_2(num_leafs);
        require(2**depth == num_leafs, "!depth");
        bytes32[] memory tree = new bytes32[](num_nodes);
        unchecked {
            for (uint i = 0; i < count(); i++) {
                tree[num_leafs + i] = commitment(i);
            }
            for (uint i = num_leafs - 1; i > 0; i--) {
                tree[i] = hash_node(tree[i * 2], tree[i * 2 + 1]);
            }
        }
        return tree;
    }

    function get_proof(bytes32[] memory tree, uint256 depth, uint256 pos) internal pure returns (bytes32[] memory) {
        bytes32[] memory decommitment = new bytes32[](depth);
        unchecked {
            uint256 index = (1 << depth) + pos;
            for (uint i = 0; i < depth; i++) {
                if (index & 1 == 0) {
                    decommitment[i] = tree[index + 1];
                } else {
                    decommitment[i] = tree[index - 1];
                }
                index = index >> 1;
            }
        }
        return decommitment;
    }

    function hash_node(bytes32 left, bytes32 right)
        internal
        pure
        returns (bytes32 hash)
    {
        assembly {
            mstore(0x00, left)
            mstore(0x20, right)
            hash := keccak256(0x00, 0x40)
        }
    }
}

////// src/truth/darwinia/ChainMessageCommitter.sol
// This file is part of Darwinia.
// Copyright (C) 2018-2022 Darwinia Network
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

/* pragma solidity 0.8.17; */

/* import "../common/MessageCommitter.sol"; */
/* import "../../interfaces/IMessageCommitter.sol"; */

/// @title ChainMessageCommitter
/// @notice Chain message committer commit messages from all lane committers
/// @dev Chain message use sparse merkle tree to commit all messages
contract ChainMessageCommitter is MessageCommitter {
    /// @dev Max of all chain position
    uint256 public maxChainPosition;
    /// @dev Bridged chain position => lane committer
    mapping(uint256 => address) public chainOf;
    /// @dev Governance role to add chains config
    address public setter;

    /// @dev Darwinia chain position
    uint256 public constant THIS_CHAIN_POSITION = 0;

    event Registry(uint256 pos, address committer);

    modifier onlySetter {
        require(msg.sender == setter, "forbidden");
        _;
    }

    constructor() {
        setter = msg.sender;
    }

    function count() public view override returns (uint256) {
        return maxChainPosition + 1;
    }

    function leaveOf(uint256 pos) public view override returns (address) {
        return chainOf[pos];
    }

    /// @dev Change the setter
    /// @notice Only could be called by setter
    /// @param _setter The new setter
    function changeSetter(address _setter) external onlySetter {
        setter = _setter;
    }

    /// @dev Registry a lane committer and could not remove it
    /// @notice Only could be called by setter
    /// @param committer Address of lane committer
    function registry(address committer) external onlySetter {
        require(THIS_CHAIN_POSITION == IMessageCommitter(committer).THIS_CHAIN_POSITION(), "!thisChainPosition");
        uint256 pos = IMessageCommitter(committer).BRIDGED_CHAIN_POSITION();
        require(THIS_CHAIN_POSITION != pos, "!bridgedChainPosition");
        require(maxChainPosition + 1 == pos, "!bridgedChainPosition");
        maxChainPosition += 1;
        chainOf[maxChainPosition] = committer;
        emit Registry(pos, committer);
    }

    /// @dev Get message proof for lane
    /// @param chainPos Bridged chain position of lane
    /// @param lanePos This lane positon of lane
    function prove(uint256 chainPos, uint256 lanePos) external view returns (MessageProof memory) {
        address committer = leaveOf(chainPos);
        return MessageProof({
            chainProof: proof(chainPos),
            laneProof: IMessageCommitter(committer).proof(lanePos)
        });
    }
}

