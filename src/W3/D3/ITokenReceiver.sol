// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

interface ITokenReceiver {
    function tokensReceived(address token, address from, uint256 amount, bytes calldata data) external returns (bool);
}