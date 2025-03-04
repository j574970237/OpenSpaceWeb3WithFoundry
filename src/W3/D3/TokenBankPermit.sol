// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Permit.sol";
import {SafeERC20, IERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

contract TokenBankPermit {
    // token address -> owner -> balance
    mapping(address => mapping(address => uint256)) public balances;
    bytes32 private constant ERC20_PERMIT_TYPEHASH =
        keccak256("Permit(address owner,address spender,uint256 value,uint256 nonce,uint256 deadline)");
    event Deposit(address indexed user, uint amount);
    event TokensReceived(address indexed token, address indexed from, uint256 value, bytes data);

    // 存款并记录每个地址的存款数量
    function deposit(address token, uint256 amount) public {
        require(amount > 0, "Amount must be greater than zero");
        bool success = ERC20(token).transferFrom(msg.sender, address(this), amount);
        require(success, "Transfer failed");
        balances[token][msg.sender] += amount;
        emit Deposit(msg.sender, amount);
    }

    // 用户提取自己的存款
    function withdraw(address token, uint256 amount) public {
        require(amount > 0, "Amount must be greater than zero");
        require(balances[token][msg.sender] >= amount, "Insufficient balance");
        balances[token][msg.sender] -= amount;
        bool success = ERC20(token).transfer(msg.sender, amount);
        require(success, "Transfer failed");
    }

    // 查询用户的存款余额
    function getBalance(address token, address user) public view returns (uint256) {
        return balances[token][user];
    }

    function tokensReceived(address token, address from, uint256 amount, bytes calldata data) external returns (bool) {
        // 调用限制
        require(msg.sender == token, "Only token contract can call this function");
        balances[token][from] += amount;
        emit TokensReceived(token, from, amount, data);
        return true;
    }

    // ⽀持离线签名授权（permit）进⾏存款
    function permitDeposit(address token, address owner, uint256 value, uint256 deadline, uint8 v, bytes32 r, bytes32 s) public {
        // 调用permit方法进行验签与授权
        ERC20Permit(token).permit(owner, address(this), value, deadline, v, r, s);

        // 存款
        balances[token][msg.sender] += value;
        uint256 balance = IERC20(token).balanceOf(address(this));
        SafeERC20.safeTransferFrom(IERC20(token), msg.sender, address(this), value);
        // 检查代币转移是否成功，不能盲目相信第三方合约的方法
        require(IERC20(token).balanceOf(address(this)) == balance + value, "Deposit token failed");
        emit Deposit(owner, value);
    }
}
