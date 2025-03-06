// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts-upgradeable/token/ERC20/ERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";

contract MyToken is Initializable, ERC20Upgradeable {
    uint256 public perMint;
    bool private init_flag;
    function initialize(string memory name, string memory symbol, uint256 initialSupply, uint256 _perMint) public initializer {
        // 控制只能调用一次，多次调用只会重置当前合约，并不会产生多个合约
        require(!init_flag, "Already init!");
        init_flag = true;
        __ERC20_init(name, symbol);
        _mint(msg.sender, initialSupply * 1e18);
        perMint = _perMint;
    }

    function mint(address account) external {
        _mint(account, perMint * 1e18);
    }
}