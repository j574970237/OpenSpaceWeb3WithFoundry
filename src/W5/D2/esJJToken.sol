// SPDX-License-Identifier: MIT 
pragma solidity ^0.8.20;

import {ERC20, IERC20Permit, ERC20Permit} from "@openzeppelin/contracts/token/ERC20/extensions/ERC20Permit.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";

contract esJJToken is ERC20, ERC20Permit {
    ERC20 public immutable token;
    address public whitelist; // 将质押池合约设为白名单
    address constant DEAD = address(0x000000000000000000000000000000000000dEaD);
    uint256 constant LOCK_PERIOD = 30 days; // 30天
    event Mint(uint256 lockId, address to, uint256 amount);

    // 与ERC20代币绑定
    constructor(ERC20 _token) ERC20("esJJToken", "esJJT") ERC20Permit("esJJToken") {
        token = _token;
    }

    // 锁仓记录
    struct LockInfo {
        address staker; // 质押者
        uint256 amount; // 锁仓量
        uint256 lockTime; // 锁仓时间
    }
    LockInfo[] public locks;

    // 发放esToken给质押者
    function mint(address staker, uint256 amount) external {
        require(token.transferFrom(msg.sender, address(this), amount), "transfer token error");
        _mint(staker, amount); // mint esToken给质押者
        LockInfo memory info = LockInfo(staker, amount, block.timestamp);
        locks.push(info);
        emit Mint(locks.length - 1, staker, amount);
    }

    // 分发挖矿奖励代币
    function burn(address staker, uint256 lockId) external {
        LockInfo memory info = locks[lockId];
        // 保证订单对应的质押者是提币者，且锁仓量大于0
        require(info.staker == staker && info.amount > 0, "lockId error");
        uint256 time = block.timestamp;
        // 计算用户可以得到的奖励代币，1 esToken 在 30 天后可兑换 1 Token，随时间线性释放，支持提前将 esToken 兑换成 Token，但锁定部分将被 burn 燃烧掉
        uint256 lockTime = info.lockTime;
        uint256 amount = info.amount;
        // 清空当前lockId对应的数据后再做操作
        info.amount = 0;
        info.staker = DEAD;
        info.lockTime = 0;
        locks[lockId] = info;
        if ((time - lockTime) < LOCK_PERIOD) {
            uint256 unlock = amount * (block.timestamp - lockTime) / LOCK_PERIOD;
            require(token.transfer(staker, unlock), "transfer unlock to staker failed");
            require(token.transfer(DEAD, amount - unlock), "burn token failed"); // 燃烧剩余代币
        } else {
            require(token.transfer(staker, amount), "transfer token failed"); // 用户不能超额提取奖励
        }
        require(transferFrom(staker, DEAD, amount), "burn esToken failed"); // 这部分esToken全部销毁
    }
}