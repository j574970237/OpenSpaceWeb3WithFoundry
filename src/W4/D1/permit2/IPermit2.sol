// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

// 从uniswap的IPermit2接口中抽取需要用的结构体与方法
interface IPermit2 {
    struct TokenPermissions {
        // ERC20 token address
        address token;
        // the maximum amount that can be spent
        uint256 amount;
    }

    /// @notice The signed permit message for a single token transfer
    struct PermitTransferFrom {
        TokenPermissions permitted;
        // a unique value for every token owner's signature to prevent signature replays
        uint256 nonce;
        // deadline on the permit signature
        uint256 deadline;
    }

    struct SignatureTransferDetails {
        // recipient address
        address to;
        // spender requested amount
        uint256 requestedAmount;
    }

    function permitTransferFrom(
        PermitTransferFrom memory permit,
        SignatureTransferDetails calldata transferDetails,
        address owner,
        bytes calldata signature
    ) external;

    // 添加 DOMAIN_SEPARATOR 方法声明
    function DOMAIN_SEPARATOR() external view returns (bytes32);
}