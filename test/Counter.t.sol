// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import {Test, console2, stdJson} from "forge-std/Test.sol";
import {Alexia} from "../src/Airdrop.sol";

contract AirdropTest is Test {
    Alexia public alexia;

    using stdJson for string;

    struct Data {
        bytes32 leaf;
        bytes32[] proof;
    }

    bytes32 merkleRoot =
0xc87618c6c49eb4b0825fe2b7323eb2d0a34647d57571acbc0eed60825db81123;

    address claimer = 0x001Daa61Eaa241A8D89607194FC3b1184dcB9B4C;
    uint claimersAmt = 45000000000000;

    Data public data;

    function setUp() public {
        alexia = new Alexia(merkleRoot);
        data = decodeMerkleTree(claimer);
    }

    function testUserCantClaimTwice() public {
        _claim();
        vm.expectRevert("You have already claimed!");
        _claim();
    }

    function testClaim() public {
        bool success = _claim();
        assertEq(alexia.balanceOf(claimer), claimersAmt);

        assertTrue(success);
    }

    function _claim() internal returns (bool success) {
        success = alexia.claim(data.proof, claimer, claimersAmt);
    }

    function decodeMerkleTree(address _claimer) internal view returns(Data memory _data){
        string memory _root = vm.projectRoot();
        string memory path = string.concat(_root, "/merkleTree.json");
        string memory json = vm.readFile(path);

        bytes memory res = json.parseRaw(
            string.concat(".", vm.toString(_claimer))
        );

        _data = abi.decode(res, (Data));
    }
}
