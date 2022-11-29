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

import "../common/LaneStorageVerifier.sol";
import "../../spec/ChainMessagePosition.sol";
import "../../interfaces/ILightClient.sol";

contract EthereumStorageVerifier is LaneStorageVerifier {
    ILightClient private light_client;

    constructor(address lightclient) LaneStorageVerifier(uint32(ChainMessagePosition.ETH), 0, 1, 2) {
        light_client = ILightClient(lightclient);
    }

    function state_root() public view override returns (bytes32) {
        return light_client.merkle_root();
    }

    function LIGHT_CLIENT() external view returns (address) {
        return address(light_client);
    }

    function changeLightClient(address lightclient) external onlySetter {
        light_client = ILightClient(lightclient);
    }

}
