// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0;

import "../../ds-test/test.sol";
import "./CommonTypes.sol";

import "hardhat/console.sol";

pragma experimental ABIEncoderV2;

contract CommonTypesTest is DSTest {
    function setUp() public {}

    function testGetLastRelayerFromVec() public {
        bytes memory data = hex"0cf41d3260d736f5b3db8a6351766e97619ea35972546a5f850bbf0b27764abe030010a5d4e8000000000000000000000000d6117e030000000000000000000000d43593c715fdd31c61141abd04a99fd6822c8558854ccde39a5684e7a56da27d00743ba40b000000000000000000000000d6117e030000000000000000000000a09c083ca783d2f2621ae7e2ee8d285c8cf103303f309b031521967db57bda140098f73e5d010000000000000000000000c817a8040000000000000000000000";
        CommonTypes.Relayer memory relayer = CommonTypes.getLastRelayerFromVec(data);
        assertTrue(relayer.fee == 20000000000);
    }
}