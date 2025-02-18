// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

interface ITokenReceiver {
    function tokensReceived(address from, uint256 amount) external returns (bool);
}

contract BaseERC20WithCallBack is ERC20 {

    constructor() ERC20("BaseERC20", "BERC20") {
        _mint(msg.sender, 100000000 * 10 ** 18);
    }
    
    function transferWithCallback(address _from, address _to, uint256 amount) public returns (bool) {
        _transfer(_from, _to, amount);
        // 在转账时，如果目标地址是合约地址，调用目标地址的 tokensReceived 方法
        if (isContract(_to)) {
            // 调用目标地址的 tokensReceived 方法
            (bool success) = ITokenReceiver(_to).tokensReceived(msg.sender, amount);
            require(success, "Callback failed");
        }
        return true;
    }

    function isContract(address account) internal view returns (bool) {
        uint256 size;
        assembly { size := extcodesize(account) }
        return size > 0;
    }
}