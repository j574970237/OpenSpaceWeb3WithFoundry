// SPDX-License-Identifier: MIT 
pragma solidity ^0.8.20;

/**
 * @title Staking Interface
 */
interface IStaking {
    /**
     * @dev 质押 ETH 到合约
     */
    function stake()  payable external;

    /**
     * @dev 赎回质押的 ETH
     * @param amount 赎回数量
     */
    function unstake(uint256 amount) external; 

    /**
     * @dev 领取 RNT Token 收益
     */
    function claim() external;

    /**
     * @dev 获取质押的 ETH 数量
     * @param account 质押账户
     * @return 质押的 ETH 数量
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev 获取待领取的 RNT Token 收益
     * @param account 质押账户
     * @return 待领取的 RNT Token 收益
     */
    function earned(address account) external view returns (uint256);
}