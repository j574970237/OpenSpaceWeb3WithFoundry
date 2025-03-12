// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {ERC20, IERC20Permit} from "@openzeppelin/contracts/token/ERC20/extensions/ERC20Permit.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {esJJToken} from "./esJJToken.sol";

contract StakePool is Ownable {
    ERC20 public immutable token; // 质押代币
    esJJToken public immutable esToken; // 挖矿奖励代币
    mapping(address => StakeInfo) public infos; // 质押者地址 -> 质押信息

    struct StakeInfo {
        uint256 staked; // 已质押的代币数量
        uint256 unCliamed; // 可提取的挖矿奖励代币数量
        uint256 lastUpdateTime; // 最后一次结算挖矿奖励的时间
    }

    constructor(ERC20 _token, esJJToken _esToken) Ownable(msg.sender) {
        token = _token;
        esToken = _esToken;
    }

    // 初始化，将所有质押奖励代币都转至合约内部
    function initStakeSupply() external onlyOwner {
        token.transferFrom(msg.sender, address(this), 3 * 1e6 * 1e18); // 总发行量的十分之三
        token.approve(address(esToken), 3 * 1e6 * 1e18);
    }

    // 质押
    function stake(uint256 amount) external {
        StakeInfo memory info = infos[msg.sender];
        uint256 time = block.timestamp;
        if (info.staked == 0 && info.lastUpdateTime == 0) {
            // 代表用户首次质押
            info.staked = amount;
            info.unCliamed = 0;
            info.lastUpdateTime = time;
        } else {
            uint256 staked = info.staked;
            uint256 claimedAdd = staked * (time - info.lastUpdateTime) / (24 * 60 * 60); // 计算这个时间段新增的挖矿奖励
            info.staked += amount;
            info.unCliamed += claimedAdd;
            info.lastUpdateTime = time;
        }
        infos[msg.sender] = info;
        token.transferFrom(msg.sender, address(this), amount);
    }

    // 领取已质押的代币
    function unStake(uint256 amount) external {
        StakeInfo memory info = infos[msg.sender];
        require(info.staked >= amount, "your staked token is less than amount");
        uint256 time = block.timestamp;
        // 结算提取之前获得的质押奖励
        uint256 staked = info.staked;
        uint256 claimedAdd = staked * (time - info.lastUpdateTime) / (24 * 60 * 60); // 计算这个时间段新增的挖矿奖励
        info.staked -= amount;
        info.unCliamed += claimedAdd;
        info.lastUpdateTime = time;
        infos[msg.sender] = info;
        token.transfer(msg.sender, amount);
    }

    // 领取质押挖矿奖励凭证esToken
    function claimEsToken() external {
        StakeInfo memory info = infos[msg.sender];
        uint256 time = block.timestamp;
        // 结算领取之前获得的质押奖励
        uint256 claimedAdd = info.staked * (time - info.lastUpdateTime) / (24 * 60 * 60); // 计算这个时间段新增的挖矿奖励
        info.unCliamed += claimedAdd;
        info.lastUpdateTime = time;
        infos[msg.sender] = info;
        require(info.unCliamed > 0, "your uncliamed token is 0");
        esToken.mint(msg.sender, info.unCliamed);
    }

    // 根据用户锁仓订单号提取相应的代币奖励
    function cliamToken(uint256 lockId) external {
        esToken.burn(msg.sender, lockId);
    }
}
