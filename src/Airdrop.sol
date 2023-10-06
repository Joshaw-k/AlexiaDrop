// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import {ERC20} from "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "solmate/src/utils/MerkleProofLib.sol";


contract Alexia is ERC20 {
    bytes32 merkleRoot;

    constructor(bytes32 _root) ERC20("ALEXIA", "ALX") {
        merkleRoot = _root;
    }

    mapping(address => bool) hasClaimed;
    event AddressClaim(address account, uint256 amount);

    function claim(
        bytes32[] calldata _merkleProof,
        address claimer,
        uint256 _amount
    ) external returns (bool success) {
        require(!hasClaimed[claimer], "You have already claimed!");
        bytes32 node = keccak256(abi.encodePacked(claimer, _amount));
        success = MerkleProofLib.verify(_merkleProof, merkleRoot, node);
        require(success, "MerkleDistributor: Invalid proof.");
        hasClaimed[claimer] = true;
        _mint(claimer, _amount);
        emit AddressClaim(claimer, _amount);
    }
}
