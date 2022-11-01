// SPDX-License-Identifier: MIT
pragma solidity 0.8.7;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract DivisibleAsset is ERC20 {
    constructor(uint256 _initialSupply, string memory name_, string memory symbol_) ERC20(name_, symbol_) {
        _mint(msg.sender, _initialSupply);
    }
}