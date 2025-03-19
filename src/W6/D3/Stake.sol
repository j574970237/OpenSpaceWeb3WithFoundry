// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "./interface/IStaking.sol";
import "./interface/IToken.sol";

contract Stake is IStaking {

    IToken public immutable token; // 质押奖励token
    uint256 public immutable rewardPerBlock; // 每一个区块产出的token奖励数量(需要乘1e18)
    uint256 public perBlockRewardRate; // 质押1个ETH可获得的区块奖励(随区块累计)，算法：前一次perBlockRewardRate + (当前区块质押1个ETH可获得的区块奖励 * 经历的区块)
    uint256 public accrualBlock; // 计算perBlockRewardRate所处的区块高度
    mapping(address => StakeInfo) public infos; // 质押者地址 -> 质押信息

    struct StakeInfo {
        uint256 staked; // 已质押的ETH数量
        uint256 unCliamed; // 可提取的奖励代币数量
        uint256 lastPerBlockRewardRate; // 最近一次更新时，质押1个ETH可获得的区块奖励
        uint256 lastUpdateBlock; // 最近一次更新时的区块高度
    }

    constructor(IToken _token, uint256 _rewardPerBlock) {
        token = _token;
        rewardPerBlock = _rewardPerBlock ;
        accrualBlock = block.number;
    }

    /**
     * @dev 质押 ETH 到合约
     */
    function stake() external payable {
        uint256 amount = msg.value;
        require(amount > 0, "stake amount is 0");
        StakeInfo memory info = infos[msg.sender];
        uint256 currentBlock = _getBlockNumber();

        // 更新累计的质押1个ETH可获得的区块奖励
        _updatePerBlockRewardRate(amount, true, currentBlock);
        if (info.staked == 0 && info.lastUpdateBlock == 0) {
            // 代表用户首次质押
            info.staked = amount;
            info.unCliamed = 0;
            info.lastPerBlockRewardRate = perBlockRewardRate;
            info.lastUpdateBlock = accrualBlock;
        } else {
            // 获取用户历史质押记录信息
            uint256 staked = info.staked;
            uint256 oldPerBlockRewardRate = info.lastPerBlockRewardRate;
            // 计算用户质押这段时间的收益
            uint256 claimedAdd = staked * (perBlockRewardRate - oldPerBlockRewardRate);
            // 更新用户质押信息
            info.staked += amount;
            info.unCliamed += claimedAdd;
            info.lastPerBlockRewardRate = perBlockRewardRate;
            info.lastUpdateBlock = accrualBlock;
        }
        infos[msg.sender] = info;
    }

    /**
     * @dev 赎回质押的 ETH
     * @param amount 赎回数量
     */
    function unstake(uint256 amount) external {
        StakeInfo memory info = infos[msg.sender];
        require(info.staked >= amount, "your staked token is less than amount");
        uint256 currentBlock = _getBlockNumber();
        // 更新累计的质押1个ETH可获得的区块奖励
        _updatePerBlockRewardRate(amount, false, currentBlock);
        // 获取用户历史质押记录信息
        uint256 staked = info.staked;
        uint256 oldPerBlockRewardRate = info.lastPerBlockRewardRate;
        // 计算用户质押这段时间的收益
        uint256 claimedAdd = staked * (perBlockRewardRate - oldPerBlockRewardRate);
        // 更新用户质押信息
        info.staked -= amount;
        info.unCliamed += claimedAdd;
        info.lastPerBlockRewardRate = perBlockRewardRate;
        info.lastUpdateBlock = accrualBlock;
        infos[msg.sender] = info;
        // 赎回ETH
        (bool success, ) = msg.sender.call{value: amount}(new bytes(0));
        require(success, "ETH transfer failed");
    }

    /**
     * @dev 领取 RNT Token 收益
     */
    function claim() external {
        StakeInfo memory info = infos[msg.sender];
        uint256 currentBlock = _getBlockNumber();
        // 更新累计的质押1个ETH可获得的区块奖励
        _updatePerBlockRewardRate(0, false, currentBlock);
        // 获取用户历史质押记录信息
        uint256 staked = info.staked;
        uint256 oldPerBlockRewardRate = info.lastPerBlockRewardRate;
        // 计算用户质押这段时间的收益
        uint256 claimedAdd = staked * (perBlockRewardRate - oldPerBlockRewardRate);
        // 本次可提取的总收益
        uint256 canClaimed = info.unCliamed + claimedAdd;
        // 更新用户质押信息
        info.unCliamed = 0;
        info.lastPerBlockRewardRate = perBlockRewardRate;
        info.lastUpdateBlock = accrualBlock;
        infos[msg.sender] = info;
        // 发放奖励代币
        token.mint(msg.sender, canClaimed);
    }

    /**
     * @dev 获取质押的 ETH 数量
     * @param account 质押账户
     * @return 质押的 ETH 数量
     */
    function balanceOf(address account) external view returns (uint256) {
        return infos[account].staked;
    }

    /**
     * @dev 获取待领取的 RNT Token 收益
     * @param account 质押账户
     * @return 待领取的 RNT Token 收益
     */
    function earned(address account) external view returns (uint256) {
        StakeInfo memory info = infos[account];
        uint256 currentBlock = _getBlockNumber();
        uint256 oldUpdateBlock = info.lastUpdateBlock;
        // 如果当前区块高度与上次更新为同一区块，则不需要重复计算
        if (currentBlock == oldUpdateBlock) {
            return infos[account].unCliamed;
        }
        // 获取用户历史质押记录信息
        uint256 staked = info.staked;
        uint256 oldPerBlockRewardRate = info.lastPerBlockRewardRate;
        // 计算用户质押这段时间的收益
        uint256 currentPerBlockRewardRate = perBlockRewardRate + (rewardPerBlock / (address(this).balance) * (currentBlock - accrualBlock)); // 只计算不更新
        uint256 claimedAdd = staked * (currentPerBlockRewardRate - oldPerBlockRewardRate);
        // 本次可提取的总收益
        return (info.unCliamed + claimedAdd);
    }

    /**
     * @dev 获取当前区块高度
     * @return 区块高度
     */
    function _getBlockNumber() internal view returns (uint256) {
        return block.number;
    }

    /**
     * @dev 更新累计的质押1个ETH可获得的区块奖励(赎回时，先调用此方法计算rate，再将ETH转给用户)
     * @param amount 质押数量
     * @param isStake 是否为质押(true-质押，false-赎回)
     * @param currentBlock 当前区块高度
     */
    function _updatePerBlockRewardRate(uint256 amount, bool isStake, uint256 currentBlock) internal {
        // 如果计算perBlockRewardRate所处的区块高度与当前区块高度一致时，不用重复计算
        if (accrualBlock == currentBlock) {
            return;
        }
        uint256 totalETH = address(this).balance;
        uint256 totalETHBefore = totalETH - amount; // 收到此笔质押ETH交易前质押池的ETH总量
        if (totalETHBefore == 0) {
            perBlockRewardRate += 0; // 质押池为空时，当前区块不产出奖励
            accrualBlock = currentBlock;
            return;
        }
        // 算法：前一次perBlockRewardRate + (当前区块质押1个ETH可获得的区块奖励 * 经历的区块)
        if (isStake) {
            perBlockRewardRate += rewardPerBlock / totalETHBefore * (currentBlock - accrualBlock);
        } else {
            perBlockRewardRate += rewardPerBlock / totalETH * (currentBlock - accrualBlock); // 赎回时，先调用此方法计算rate，再将ETH转给用户
        }
        accrualBlock = currentBlock;
    }
}
