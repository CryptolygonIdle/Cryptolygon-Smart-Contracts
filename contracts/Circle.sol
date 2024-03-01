// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Burnable.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";
import "./interfaces/ICircle.sol";

contract Circle is ICircle, ERC20, ERC20Burnable, AccessControl  {
    bytes32 public constant GAME_ROLE = keccak256("GAME_ROLE");
    bytes32 public constant BURNER_ROLE = keccak256("BURNER_ROLE");

    constructor(address defaultAdmin)
        ERC20("Circle", "CCL")
    {
        _grantRole(DEFAULT_ADMIN_ROLE, defaultAdmin);
    }

    function mint(address to, uint256 amount) public onlyRole(GAME_ROLE) {
        _mint(to, amount);
    }

    function allowGameToSpend(address owner) public onlyRole(GAME_ROLE) {
        _approve(owner, msg.sender, type(uint256).max);
    }
}