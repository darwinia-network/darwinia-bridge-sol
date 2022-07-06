// SPDX-License-Identifier: Apache-2.0

pragma solidity 0.7.6;
pragma abicoder v2;

import "../test.sol";
import "../../spec/BinanceSmartChain.sol";

contract BinanceSmartChainTest is DSTest, BinanceSmartChain {
    uint64 constant private CHAIN_ID = 56;

    function test_hash_rlp_block_header() public {
        BSCHeader memory header = build_block_header();
        assertEq0(rlp(header), hex'f90403a05cb4b6631001facd57be810d5d1383ee23a31257d2430f097291d25fc1446d4fa01dcc4de8dec75d7aab85b567b6ccd41ad312451b948a7413f0a142fd40d4934794e9ae3261a475a27bb1028f140bc2a7c843318afda0a6cd7017374dfe102e82d2b3b8a43dbe1d41cc0e4569f3dc45db6c4e687949aea0657f5876113ac9abe5cf0460aa8d6b3b53abfc336cea4ab3ee594586f8b584caa01bfba16a9e34a12ff7c4b88be484ccd8065b90abea026f6c1f97c257fdb4ad2bb901002c30123db854d838c878e978cd2117896aa092e4ce08f078424e9ec7f2312f1909b35e579fb2702d571a3be04a8f01328e51af205100a7c32e3dd8faf8222fcf03f3545655314abf91c4c0d80cea6aa46f122c2a9c596c6a99d5842786d40667eb195877bbbb128890a824506c81a9e5623d4355e08a16f384bf709bf4db598bbcb88150abcd4ceba89cc798000bdccf5cf4d58d50828d3b7dc2bc5d8a928a32d24b845857da0b5bcf2c5dec8230643d4bec452491ba1260806a9e68a4a530de612e5c2676955a17400ce1d4fd6ff458bc38a8b1826e1c1d24b9516ef84ea6d8721344502a6c732ed7f861bb0ea017d520bad5fa53cfc67c678a2e6f6693c8ee02837594c884038ff37a84013640178460ac7137b90205d883010100846765746888676f312e31352e35856c696e7578000000fc3ca6b72465176c461afb316ebc773c61faee85a6515daa295e26495cef6f69dfa69911d9d8e4f3bbadb89b29a97c6effb8a411dabc6adeefaa84f5067c8bbe2d4c407bbe49438ed859fe965b140dcf1aab71a93f349bbafec1551819b8be1efea2fc46ca749aa14430b3230294d12c6ab2aac5c2cd68e80b16b581685b1ded8013785d6623cc18d214320b6bb6475970f657164e5b75689b64b7fd1fa275f334f28e1872b61c6014342d914470ec7ac2975be345796c2b7ae2f5b9e386cd1b50a4550696d957cb4900f03a8b6c8fd93d6f4cea42bbb345dbc6f0dfdb5bec739bb832254baf4e8b4cc26bd2b52b31389b56e98b9f8ccdafcc39f3c7d6ebf637c9151673cbc36b88a6f79b60359f141df90a0c745125b131caaffd12b8f7166496996a7da21cf1f1b04d9b3e26a3d077be807dddb074639cd9fa61b47676c064fc50d62cce2fd7544e0b2cc94692d4a704debef7bcb61328e2d3a739effcd3a99387d015e260eefac72ebea1e9ae3261a475a27bb1028f140bc2a7c843318afdea0a6e3c511bbd10f4519ece37dc24887e11b55dee226379db83cffc681495730c11fdde79ba4c0c0670403d7dfc4c816a313885fe04b850f96f27b2e9fd88b147c882ad7caf9b964abfe6543625fcca73b56fe29d3046831574b0681d52bf5383d6f2187b6276c100a00000000000000000000000000000000000000000000000000000000000000000880000000000000000');
        assertEq(hash(header), hex'7e1db1179427e17c11a42019f19a3dddf326b6177b0266749639c85c78c607bb');
    }

    function test_hash_rlp_with_chain_id_block_header() public {
        BSCHeader memory header = build_block_header();
        assertEq0(rlp_chain_id(header, CHAIN_ID), hex'f9040438a05cb4b6631001facd57be810d5d1383ee23a31257d2430f097291d25fc1446d4fa01dcc4de8dec75d7aab85b567b6ccd41ad312451b948a7413f0a142fd40d4934794e9ae3261a475a27bb1028f140bc2a7c843318afda0a6cd7017374dfe102e82d2b3b8a43dbe1d41cc0e4569f3dc45db6c4e687949aea0657f5876113ac9abe5cf0460aa8d6b3b53abfc336cea4ab3ee594586f8b584caa01bfba16a9e34a12ff7c4b88be484ccd8065b90abea026f6c1f97c257fdb4ad2bb901002c30123db854d838c878e978cd2117896aa092e4ce08f078424e9ec7f2312f1909b35e579fb2702d571a3be04a8f01328e51af205100a7c32e3dd8faf8222fcf03f3545655314abf91c4c0d80cea6aa46f122c2a9c596c6a99d5842786d40667eb195877bbbb128890a824506c81a9e5623d4355e08a16f384bf709bf4db598bbcb88150abcd4ceba89cc798000bdccf5cf4d58d50828d3b7dc2bc5d8a928a32d24b845857da0b5bcf2c5dec8230643d4bec452491ba1260806a9e68a4a530de612e5c2676955a17400ce1d4fd6ff458bc38a8b1826e1c1d24b9516ef84ea6d8721344502a6c732ed7f861bb0ea017d520bad5fa53cfc67c678a2e6f6693c8ee02837594c884038ff37a84013640178460ac7137b90205d883010100846765746888676f312e31352e35856c696e7578000000fc3ca6b72465176c461afb316ebc773c61faee85a6515daa295e26495cef6f69dfa69911d9d8e4f3bbadb89b29a97c6effb8a411dabc6adeefaa84f5067c8bbe2d4c407bbe49438ed859fe965b140dcf1aab71a93f349bbafec1551819b8be1efea2fc46ca749aa14430b3230294d12c6ab2aac5c2cd68e80b16b581685b1ded8013785d6623cc18d214320b6bb6475970f657164e5b75689b64b7fd1fa275f334f28e1872b61c6014342d914470ec7ac2975be345796c2b7ae2f5b9e386cd1b50a4550696d957cb4900f03a8b6c8fd93d6f4cea42bbb345dbc6f0dfdb5bec739bb832254baf4e8b4cc26bd2b52b31389b56e98b9f8ccdafcc39f3c7d6ebf637c9151673cbc36b88a6f79b60359f141df90a0c745125b131caaffd12b8f7166496996a7da21cf1f1b04d9b3e26a3d077be807dddb074639cd9fa61b47676c064fc50d62cce2fd7544e0b2cc94692d4a704debef7bcb61328e2d3a739effcd3a99387d015e260eefac72ebea1e9ae3261a475a27bb1028f140bc2a7c843318afdea0a6e3c511bbd10f4519ece37dc24887e11b55dee226379db83cffc681495730c11fdde79ba4c0c0670403d7dfc4c816a313885fe04b850f96f27b2e9fd88b147c882ad7caf9b964abfe6543625fcca73b56fe29d3046831574b0681d52bf5383d6f2187b6276c100a00000000000000000000000000000000000000000000000000000000000000000880000000000000000');
        assertEq(keccak256(rlp_chain_id(header, CHAIN_ID)), hex'f65a0890665c9afd33d018ad6b043f265db1dc91cb0580fcbc627b050f88047e');
    }

    function build_block_header() internal pure returns (BSCHeader memory header) {
        header = BSCHeader({
            difficulty: 0x02,
            extra_data: hex'd883010100846765746888676f312e31352e35856c696e7578000000fc3ca6b72465176c461afb316ebc773c61faee85a6515daa295e26495cef6f69dfa69911d9d8e4f3bbadb89b29a97c6effb8a411dabc6adeefaa84f5067c8bbe2d4c407bbe49438ed859fe965b140dcf1aab71a93f349bbafec1551819b8be1efea2fc46ca749aa14430b3230294d12c6ab2aac5c2cd68e80b16b581685b1ded8013785d6623cc18d214320b6bb6475970f657164e5b75689b64b7fd1fa275f334f28e1872b61c6014342d914470ec7ac2975be345796c2b7ae2f5b9e386cd1b50a4550696d957cb4900f03a8b6c8fd93d6f4cea42bbb345dbc6f0dfdb5bec739bb832254baf4e8b4cc26bd2b52b31389b56e98b9f8ccdafcc39f3c7d6ebf637c9151673cbc36b88a6f79b60359f141df90a0c745125b131caaffd12b8f7166496996a7da21cf1f1b04d9b3e26a3d077be807dddb074639cd9fa61b47676c064fc50d62cce2fd7544e0b2cc94692d4a704debef7bcb61328e2d3a739effcd3a99387d015e260eefac72ebea1e9ae3261a475a27bb1028f140bc2a7c843318afdea0a6e3c511bbd10f4519ece37dc24887e11b55dee226379db83cffc681495730c11fdde79ba4c0c0670403d7dfc4c816a313885fe04b850f96f27b2e9fd88b147c882ad7caf9b964abfe6543625fcca73b56fe29d3046831574b0681d52bf5383d6f2187b6276c100',
            gas_limit: 0x038ff37a,
            gas_used: 0x01364017,
            log_bloom: hex'2c30123db854d838c878e978cd2117896aa092e4ce08f078424e9ec7f2312f1909b35e579fb2702d571a3be04a8f01328e51af205100a7c32e3dd8faf8222fcf03f3545655314abf91c4c0d80cea6aa46f122c2a9c596c6a99d5842786d40667eb195877bbbb128890a824506c81a9e5623d4355e08a16f384bf709bf4db598bbcb88150abcd4ceba89cc798000bdccf5cf4d58d50828d3b7dc2bc5d8a928a32d24b845857da0b5bcf2c5dec8230643d4bec452491ba1260806a9e68a4a530de612e5c2676955a17400ce1d4fd6ff458bc38a8b1826e1c1d24b9516ef84ea6d8721344502a6c732ed7f861bb0ea017d520bad5fa53cfc67c678a2e6f6693c8ee',
            coinbase: 0xE9AE3261a475a27Bb1028f140bc2a7c843318afD,
            mix_digest: 0x0000000000000000000000000000000000000000000000000000000000000000,
            nonce: 0x0000000000000000,
            number: 0x7594c8,
            parent_hash: 0x5cb4b6631001facd57be810d5d1383ee23a31257d2430f097291d25fc1446d4f,
            receipts_root: 0x1bfba16a9e34a12ff7c4b88be484ccd8065b90abea026f6c1f97c257fdb4ad2b,
            uncle_hash: 0x1dcc4de8dec75d7aab85b567b6ccd41ad312451b948a7413f0a142fd40d49347,
            state_root: 0xa6cd7017374dfe102e82d2b3b8a43dbe1d41cc0e4569f3dc45db6c4e687949ae,
            timestamp: 0x60ac7137,
            transactions_root: 0x657f5876113ac9abe5cf0460aa8d6b3b53abfc336cea4ab3ee594586f8b584ca
        });
    }

    function test_hash_block_header() public {
        BSCHeader memory header = BSCHeader({
            difficulty: 0x02,
            extra_data: hex'd883010a02846765746888676f312e31352e35856c696e75780000001600553da20e656b63140f5ddb166f5eb0cc7ac5fbf19995ad52e8e62e67210699d8cb0a7e7208c38784c37687e28ddda763a96f7102b6e88d9f184b7bcb955582018a5901',
            gas_limit: 0x1c9c1b6,
            gas_used: 0x561c3,
            log_bloom: hex'00800000000000000000000000800000000000000000400040000000000000000000400000000000000000000040000000002001000000000000000000010000010000000000000000000008000000002012000000000010000004000000008000000020080200000000000400000000000000000000000000000010000000000000010000000010000000800000000008000400000001000000000100000080000000040000000001000000020000000000000012000000020010000000000000000002000000000000000000000e00000000800000000000000080000001010000002000000002010000000000000000200000000004000060200000080000',
            coinbase: 0x35552c16704d214347f29Fa77f77DA6d75d7C752,
            mix_digest: 0x0000000000000000000000000000000000000000000000000000000000000000,
            nonce: 0x0000000000000000,
            number: 0x913701,
            parent_hash: 0x6f6c70883a2955357e9a1b6be693cf180340a93c54db86351b4649b728da0035,
            receipts_root: 0xc35b5aaec2d96cf4ec6682d0fadbee1e206c8cc8f134e5ca5195369c039bbb40,
            uncle_hash: 0x1dcc4de8dec75d7aab85b567b6ccd41ad312451b948a7413f0a142fd40d49347,
            state_root: 0xf49d2ef4130d8ce248b8035186e35d114cb6133af431e61d8b3fc7c2b9663204,
            timestamp: 0x60bdbdf0,
            transactions_root: 0x67f7b4fcddf5e20489ddde0f5ef9e0454a181cbd3216b036ed52cb6c212bfa08
        });
        assertEq(hash(header), hex'0a14634e263cd6cee555cd7178051be08199e793c8ebbfec628bf8796bf09a74');
    }
}
