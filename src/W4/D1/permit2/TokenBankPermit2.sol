// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {SafeERC20, IERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import {IPermit2} from "./IPermit2.sol";

contract TokenBankPermit2 {
    // token address -> owner -> balance
    mapping(address => mapping(address => uint256)) public balances;
    // token address -> owner -> nonce
    mapping(address => mapping(address => uint256)) public nonces;
    IPermit2 public immutable PERMIT2;
    
    event Deposit(address indexed user, uint amount);
    event TokensReceived(address indexed token, address indexed from, uint256 value, bytes data);

    constructor(IPermit2 permit_) {
        PERMIT2 = permit_;
    }

    // 存款并记录每个地址的存款数量
    function deposit(address token, uint256 amount) public {
        require(amount > 0, "Amount must be greater than zero");
        bool success = IERC20(token).transferFrom(msg.sender, address(this), amount);
        require(success, "Transfer failed");
        balances[token][msg.sender] += amount;
        emit Deposit(msg.sender, amount);
    }

    // 用户提取自己的存款
    function withdraw(address token, uint256 amount) public {
        require(amount > 0, "Amount must be greater than zero");
        require(balances[token][msg.sender] >= amount, "Insufficient balance");
        balances[token][msg.sender] -= amount;
        bool success = IERC20(token).transfer(msg.sender, amount);
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

    // 使用 permit2 进行签名授权转账来进行存款
    function depositWithPermit2(address token, uint256 amount, uint256 nonce, uint256 deadline, bytes calldata signature) public {
        nonces[token][msg.sender]++;
        // 存款
        balances[token][msg.sender] += amount;

        PERMIT2.permitTransferFrom(
            // The permit message. Spender will be inferred as the caller (us).
            IPermit2.PermitTransferFrom({
                permitted: IPermit2.TokenPermissions({
                    token: token,
                    amount: amount
                }),
                nonce: nonce,
                deadline: deadline
            }),
            // The transfer recipient and amount.
            IPermit2.SignatureTransferDetails({
                to: address(this),
                requestedAmount: amount
            }),
            // The owner of the tokens, which must also be
            // the signer of the message, otherwise this call
            // will fail.
            msg.sender,
            // The packed signature that was the result of signing
            // the EIP712 hash of `permit`.
            signature
        );
    }

    function getNonceForPermit2(address token, address user) public view returns (uint256) {
        return nonces[token][user];
    }
}
