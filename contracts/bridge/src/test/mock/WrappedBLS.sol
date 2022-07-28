// SPDX-License-Identifier: MIT

pragma solidity 0.7.6;
pragma abicoder v2;

import "../test.sol";
import "../../utils/Bytes.sol";
import "../../utils/bls12381/BLS.sol";

contract WrappedBLS is DSTest {
    using Bytes for bytes;

    function expand_message_xmd(bytes32 message) public pure returns (bytes memory) {
        return BLS.expand_message_xmd(message);
    }

    function hash_to_field_fq2(bytes32 message) public view returns (Fp2[2] memory result) {
        return BLS.hash_to_field_fq2(message);
    }

    function map_to_curve(Fp2 memory f) public view returns (G2Point memory) {
        return G2.map_to_curve(f);
    }

    function hash_to_curve_g2(bytes32 message) public view returns (G2Point memory) {
        return BLS.hash_to_curve_g2(message);
    }

    function bls_pairing_check(G1Point memory pk, G2Point memory h, G2Point memory s) public view returns (bool) {
        return BLS.bls_pairing_check(pk, h, s);
    }

    function deserialize_g1(bytes memory g1) public pure returns (G1Point memory) {
        return G1.deserialize(g1);
    }

    function serialize_g1(G1Point memory g1) public pure returns (bytes memory) {
        return G1.serialize(g1);
    }

    function deserialize_g2(bytes memory g2) public pure returns (G2Point memory) {
        return G2.deserialize(g2);
    }

    function serialize_g2(G2Point memory g2) public pure returns (bytes memory) {
        return G2.serialize(g2);
    }

    function aggregate_pks(bytes[] calldata pubkeys) public view returns (G1Point memory) {
        return BLS.aggregate_pks(pubkeys);
    }

    function fast_aggregate_verify(
        bytes[] calldata uncompressed_pubkeys,
        bytes32 message,
        bytes calldata uncompressed_signature
    ) public view returns (bool) {
        return BLS.fast_aggregate_verify(uncompressed_pubkeys, message, uncompressed_signature);
    }

    function encode_g1(G1Point memory p) public pure returns (bytes memory) {
        return abi.encodePacked(
            p.x.a,
            p.x.b,
            p.y.a,
            p.y.b
        );
    }

    function decode_g1(bytes memory x) public pure returns (G1Point memory) {
        return G1Point(
            Fp(x.slice_to_uint(0, 32),  x.slice_to_uint(32, 64)),
            Fp(x.slice_to_uint(64, 96), x.slice_to_uint(96, 128))
        );
    }

    function add_g1(bytes memory input) public view returns (bytes memory) {
        G1Point memory p0 = decode_g1(input.substr(0, 128));
        G1Point memory p1 = decode_g1(input.substr(128, 128));
        G1Point memory q = G1.add(p0, p1);
        return encode_g1(q);
    }

    function map_to_curve_g1(bytes memory input) public view returns (bytes memory) {
        Fp memory f = Fp(input.slice_to_uint(0, 32), input.slice_to_uint(32, 64));
        G1Point memory p = G1.map_to_curve(f);
        return encode_g1(p);
    }

    function encode_g2(G2Point memory p) public pure returns (bytes memory) {
        return abi.encodePacked(
            p.x.c0.a,
            p.x.c0.b,
            p.x.c1.a,
            p.x.c1.b,
            p.y.c0.a,
            p.y.c0.b,
            p.y.c1.a,
            p.y.c1.b
        );
    }

    function decode_g2(bytes memory x) public pure returns (G2Point memory) {
        return G2Point(
            Fp2(
                Fp(x.slice_to_uint(0, 32),  x.slice_to_uint(32, 64)),
                Fp(x.slice_to_uint(64, 96), x.slice_to_uint(96, 128))
            ),
            Fp2(
                Fp(x.slice_to_uint(128, 160),  x.slice_to_uint(160, 192)),
                Fp(x.slice_to_uint(192, 224), x.slice_to_uint(224, 256))
            )
        );
    }

    function add_g2(bytes memory input) public view returns (bytes memory) {
        G2Point memory p0 = decode_g2(input.substr(0, 256));
        G2Point memory p1 = decode_g2(input.substr(256, 256));
        G2Point memory q = G2.add(p0, p1);
        return encode_g2(q);
    }

    function test_add_g1() public {
        bytes memory x = hex'0000000000000000000000000000000017f1d3a73197d7942695638c4fa9ac0fc3688c4f9774b905a14e3a3f171bac586c55e83ff97a1aeffb3af00adb22c6bb0000000000000000000000000000000008b3f481e3aaa0f1a09e30ed741d8ae4fcf5e095d5d00af600db18cb2c04b3edd03cc744a2888ae40caa232946c5e7e10000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000';
        assertEq0(add_g1(x), hex'0000000000000000000000000000000017f1d3a73197d7942695638c4fa9ac0fc3688c4f9774b905a14e3a3f171bac586c55e83ff97a1aeffb3af00adb22c6bb0000000000000000000000000000000008b3f481e3aaa0f1a09e30ed741d8ae4fcf5e095d5d00af600db18cb2c04b3edd03cc744a2888ae40caa232946c5e7e1');
    }
}
