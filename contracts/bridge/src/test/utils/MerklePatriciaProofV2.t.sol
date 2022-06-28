// SPDX-License-Identifier: Apache-2.0

pragma solidity 0.7.6;

import "../test.sol";
import "../../utils/MerklePatriciaProofV1.sol";
import "../../utils/RLPEncode.sol";

contract MerklePatriciaProofV2Test is DSTest {

    function test_verify_single_storage_proof() public {
        bytes32 root = 0xb85b566e523eab932fb0a61d793849eb87db81c39b008d9146589423eee299f1;
        address account = 0x2091125994a6836252118Ddae37d019F8E6CA455;
        bytes memory paths = abi.encodePacked(keccak256(abi.encodePacked(account)));
        // uint paths = uint(keccak256(abi.encodePacked(account)));
        bytes[] memory proof = new bytes[](8);
        proof[0] = hex'f90211a02b197aa094abdb8f1a71c8523b5fbced57c31a9b9baed2d41c180c7bbbaccee8a00b5bb0c2b428df4059129cba76d01c3547ea485bc4cad1fbb1c65f6f496ba09fa05b6635866f9c2600a293784bd3f0e3ccbc49e31bb49057ff4a163e9b40feb860a0414c4489b1c1157a559228cf3836a690098bf30ee49c7b20c63d069536db53f9a0c35ca7a85560b146fa40d95896b9e0f0efc246a72f3ed552182f4937741669bfa02fd583b6cbd2f094f1bd7187a59f30660f775af6f00861a02c12b01203b0807ba06601b9213fb3c1152886620f0aa6d76c598878e782eb7d5353aeaf20d7ffb9aba0e946ea8c488924c734454edd585bdf64929f861ad9c0a672c6cb11e5994d621ba02bd7fe141350cb43b56bcf202654810ab8eb6b527cc0f85a548a7a13be115ffda010226b47d92a228aa79752fcddd4f483236df7988786a1c014dc7467f8397179a0baa67930fb41c14b734d3ffc777fdabbbf2012ac8619586d9143c6e0d4fdb4eaa07df12c126be51db32da195b73351515059255867352d94976d9b73758ebec4d9a030a750d67de6c90565e2f6f13dc2ff042a27f8f5f5f4f2e421633f9aea26c478a0f0e15c129747041867f0f21a1e0eaad8d8be22835d9bdd6f9db7cb1d1d36a68aa00d8d917584c25fe09f31ed8af1578d45e4b7c5ec55d8e4e00b871b36481cff5ea0b9c4aada8c74d0773276dca8967b60a8c49074c05b7f7adae4ae3038ab38e5d480';
        proof[1] = hex'f90211a075573c7a6256004d0c8277fe4a25fe2b79a385fe718c223f80adfe12faf75131a08621c559e68942d42e3996c10b51b854f89d25f6393ac9d1c8a9dbf948ea8541a00e56b5561311bebc5818f941e259d9c732b2276895b9726d0316e5466a6fb807a0ee682e275a0fbfaaa61354e89bff6782fdbc3afaa7071fb3f888bb96485b741ba052d2e23bba6ff2dd5699d1a0a5e90582e25921d0fc156de563f97059667d320da0838c42f4b0a3dd62822a17f1fa17901fb7c681e8cc772e57b0a4ac078845dbb2a032248e368afdf9cab9ad5c209608a89dc1e59b9a001df78d09199dde7ee43184a0693844a68419c98b3366cad719b69f230a92203863b9b49aec000ff53f800843a07221eb547df126f2e5f66f8d331c35a663b407af16f312320ba77235d3377c74a07e0a761071eeb15e0582e9e61f8247dbfc7e0125ecfcbe3d3e6201ecde2cf1f2a06bf4053d9cac9e9bac37155a9a4ce2acd7e57131f71eac15627e5c2923da2b0aa04782d358da3d3202971989f8b2cd3f73c35f3bd22d0a85945febcc180572c5bfa035490fdb74d8115bfa4247592ba493f3dc8b5ff2510e5e6d8718bd568ea10fb5a07604858fa9f57e90dc12c334cc0cb2024db8dbdada47922253f358024663d9afa03785f9c1324ecc2cb7c68cfac77a13ce9bcc3dbb409d57902e39454e61571d82a0158dc7a21abfd0399ff6c58cf941609343f8e58e6912b598b433acf9f5cc995380';
        proof[2] = hex'f90211a02eb1a98845cbe6fa6696168e5e3f8a0accebbb2a823bfdfe874e51c71d396ca8a09b47207b9ea57fc32a066e8eb9cdfb66970205d9d76cc936ef4328769db7a941a022d93623f2a5d8b7439de7cdf4f7a5aa64b04212053cde623bfe72877863ccb0a074e9a8588b83b2d1b5539fe59fb8e58c54f53339ca121e2eb98783f524a84409a0c5caf472d5fe09fbcc1ceed7f2822b4fd38b4f7de8265d5cfe3f151c23e49dfca02b82576afb1da86f074be7c528a88a1f3a2eae480aa91166dc531cdf6aa32d4ca0fc795aace50b3b2304e14549159f289408fe785bd52779fc08d18e1e7afc6d3fa0e6ce4e99d8753862e0233a7522dc0632becc77aa5e2a6a9cba434723a761b7eaa071a7c9f7748f688108284d3c7afdd19d0ab42240b1ea0df46dc2f7071964be4ba0f2d5f99d3c792afe437b5c59cbeb24c0a11ec12247fabdfc6a755fba88eb9c93a05b0d9202babdd9d11985f79a346b2a81f70b1feca862da9c92ae7dfd52ee978fa011d6093571d26873add93c65c7d123d5aac2d259bca9acdbf19ffb59691ccf02a09e04686fc93c8f65b8c31b56b2ed1c482241cdababbcf9fda1d683d7aa8fb9bfa039a7dab838b90eb70776811fad1104dfb2713508c27207123e04a251c371db4ca02a2db4e2b41e2c31a5b9d67fe2ded77e4fa83bb126b3b32599b10f88ec62fbf9a033b660a93c0b12d40ee969e9cc9a4edfb8ef3a0fb71786ea3339b1cbd699d6ff80';
        proof[3] = hex'f90211a0487ebf42ad517e3fb77a40021eda9095da276ac0cc5e8e94fa54b4e8b6f9faf3a02006ef6f7f0fec79431ca4e90f785b7c8c14b60c65eb46cfcb793eada0e69be1a0145455c17c76e27a40433e2dca22c1201e023ee22eecafcbd39e9958933a0e6ba0b7112c592547d1e9722168107b4b2c983b049892e5fb72e86b9933d06261d0cca0a0989231d89c310c715838d19acfb1f750be4076a548d1403fd11d6b72182a42a0f262dba2c10c5a31a2e26eb657286d99c3ab4079f4d59a0d5eefe59310998b6ca061280198c681d65e7104a9e3365775605b7b6d7862a0e8da65e713182cdfb7dca07ffd524f73b6ac9f94485a1d2620e2dbe2c306d6575a6973e1fc083f9ddca912a08c31fa832b473b58d42fe4ab8c3fb80bed135bb6f58724e763d8fb6ebc012006a0613baa32a58881fbe4ca58f04dc1209d81317cff4415e3484ab672f11e22324ba04285388cf9779366dc221167f95c57dbd60f6797986468f535b024a9ea69595aa06669327882c049fb3cbd113302964643b0c538b124144e2a532b5f827ac60d14a0877393867e668bd78df09af6a491ad7e63faa1883473c549c6ec8358a1a57568a009c0226243b42847d1c7e2f273cbfa413cf3283966f54e1d75bd70ad8ee26fe6a0d4c752b873991c0d69949cdf720103634b7147ccd89bcb85ac30efdf541367daa0f2c390850d1a8d341d6e37171bc46c7d0dd40de92f1e25ef9f7aeaff16dddbc280';
        proof[4] = hex'f90211a0a5954f4e4d0fdd5a37e6867467a4be9115dff722e5ccb3fb2c37283dd5d51603a034c7606963d151a1cf69f9691b047b2dc54c910683a0a5a2f63ef16cf42f4f6ea027739ecf16d538570cb1dd10fac3fbcc4947dff98cc51adfa85537911f1ec62ea0d8936b41a794f8c070c547d141fb8bd596adcf599fdcc313277a2bb3c25f68c3a05284cbafe0dccae76c73d6b64955f95adc77dcd001cddf0f90530495d6e81bf5a00296067cd4636ed0133edda8dc423de508b84bfad371b387060f42b7c1970f31a05560f85c27b2d3b8ba006977b66164483de9ec1fe84ac0e32d061383e436a6d3a0acd1d0ceabdc8479934b7c430fc8d96e07339950457c141b2378dd10da2466dba0c1c461a1f4083379cd0bb6182e3055688a20aba2cb064beb2a281d331d1ca00ca04b146e2bab4b6c58be3cb021812650ee40bbff7a2d72ad2e5be14b360fc08b66a07f8afc94a8bf4f05d193b0e6592f51cb95bb0e540e00e11941389f9f0fe5bc89a03dc5270c5bb7b97d722dd92f08c1ac9cca723e5969ace9871e6cd6132243cbf1a0518e863bfec34059ddf6e46b4657a89fce48567acc5a480e0c0b2ca4269fa31fa094705db84ab6adf0ae7982780c7742630f5bb661d1dcac1e80d2f00ad678605ca0c7f79171afe04a11c1e50ba2b647d90ef2efd47042754bae82b48cd92e2e3f6ba006a341874608d81dbdd03023f7b4ebc939fba6903aa629f7fad80daa48ac2b8980';
        proof[5] = hex'f901f1a0f917707e49550f2b996ec541e5c07c5e0438135ca8577cfd93295723a8199135a0136774f84e20e0d4cc54d0f86771df33ff7a71f5c716fce828b3f09b6391fc2ca0377bbfff5fb6f4a4e7feece59d91186c4d4b003e3e23c935c6f410327a2476d3a0b2836890f22d75c3a95ada7b609b75a9997a48a11dcfbf645f6a5bade924a0c4a071450d082868865a21985d2594f78b78c7783199118365f83a124362863f7612a05cde7da422cc1955b54b4078d054de8e37b2805c7077613282a0f664615aefeca03e27387c1956ad73dbc6c18f8aaf4d158c0fce5f378ed2c737403d17db10eb8b80a0689847148187a5d0a99e17b9043841b2fe0481e15bc4fa783d21f412574a616ea0cc533d4874e07d8d4e868d601378bca9c288354cea74b0a824a45a1cd9697914a03b4eca732dd04a8581eafd379a1ed3ef1c10dac5a3f27e2a2d25c35056eb34bda0fc8d282f1d8ca3732ffd25de18ec2987b9bf757a6a3e3097344072da02e566bca00324883899e1d9a2b66f71e19eeaf8a32b6313b28f500391aa6eb38119c61261a07ad389ad23fc7373db36d52eab19b9dc574d82358db8a28d0914138f4e6762efa07f85b2277215c39de1db05f41e727d65367b8862c3f09f2b33d3ade903fb3024a05894a37f31a6459c35245c897cbf37a948fb96a7bd9c952cc401a1b126c7b67380';
        proof[6] = hex'f8918080a08c493bb747352aeb7eb9b5bbff376fc07b84a6178552edd5a8f30250d5d4348280808080a01df396569ea87a6378d7dd35e26a654700f94df03421a37918f9868fd4a43c69a067abaabe4b1c0b0c38d79aa67f7d44614570aa95ff46c6837fa3e836e8a42a1680808080a06145441772405e509d424204248af30cda9da4a080b1748ddf5121c3536e2fa0808080';
        proof[7] = hex'f8669d3d6ef56197b6a07600138cb2a498a2139c82f3dff1c1958c3fe99fdc77b846f8440180a088bf311c759a8e9f6dac6b21a06d907ce6f192bdf08aa7de7c2fe008f7956087a0bea4e8de3e083450d67658272d677d5b235afa1fb72bc1ee3aa9b93e4cf7d23f';
        // assertEq0(MerklePatriciaProofV2.validateProof(root, paths, RLPEncode.encodeList(proof)), hex'');
        assertEq0(MerklePatriciaProofV1.validateMPTProof(root, paths, RLPEncode.encodeList(proof)), hex'');
    }
}
