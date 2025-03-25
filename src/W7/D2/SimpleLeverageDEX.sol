// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

// 极简的杠杆 DEX 实现
contract SimpleLeverageDEX {
    uint256 public vK; // 1000000
    uint256 public vETHAmount;
    uint256 public vUSDCAmount;

    IERC20 public USDC; // 自己创建一个币来模拟 USDC

    struct PositionInfo {
        uint256 margin; // 保证金    // 真实的资金， 如 USDC
        uint256 borrowed; // 借入的资金
        int256 position; // 虚拟 eth 持仓
    }

    mapping(address => PositionInfo) public positions;

    constructor(IERC20 _USDC, uint256 vEth, uint256 vUSDC) {
        USDC = _USDC;
        vETHAmount = vEth;
        vUSDCAmount = vUSDC;
        vK = vEth * vUSDC;
    }

    receive() external payable {}

    // 开启杠杆头寸
    function openPosition(uint256 _margin, uint256 level, bool long) external {
        require(positions[msg.sender].position == 0, "Position already open");

        PositionInfo storage pos = positions[msg.sender];

        USDC.transferFrom(msg.sender, address(this), _margin); // 用户提供保证金
        uint256 amount = _margin * level;
        uint256 borrowAmount = amount - _margin;

        pos.margin = _margin;
        pos.borrowed = borrowAmount;

        // 计算用户的虚拟eth持仓, 并更新vETHAmount和vUSDCAmount
        if (long) {
            pos.position = int256(vETHAmount) - int256((vK / (vUSDCAmount + amount)));
            vUSDCAmount = vUSDCAmount + amount;
            vETHAmount = vK / vUSDCAmount;
        } else {
            pos.position = int256(vETHAmount) - int256((vK / (vUSDCAmount - amount))); // 做空时，为负数
            vUSDCAmount = vUSDCAmount - amount;
            vETHAmount = vK / vUSDCAmount;
        }
    }

    // 关闭头寸并结算, 不考虑协议亏损
    function closePosition() external {
        PositionInfo memory position = positions[msg.sender];
        require(position.position != 0, "No open position");

        int256 USDCNow; // 当前仓位价值
        // 进行清算, 更新vETHAmount和vUSDCAmount
        if (position.position > 0) {
            uint256 USDCAmountLast = vUSDCAmount;
            vETHAmount = vETHAmount + uint256(position.position);
            vUSDCAmount = vK / vETHAmount;
            USDCNow = int256(USDCAmountLast) - int256(vUSDCAmount);
        } else {
            uint256 USDCAmountLast = vUSDCAmount;
            vETHAmount = vETHAmount - uint256(-position.position); // 此时的position.position为负数
            vUSDCAmount = vK / vETHAmount;
            USDCNow = int256(vUSDCAmount) - int256(USDCAmountLast);
        }
        int256 pnl = USDCNow - int256(position.margin) - int256(position.borrowed);
        if (pnl > 0) {
            USDC.transfer(msg.sender, position.margin + uint256(pnl));
        } else {
            USDC.transfer(msg.sender, position.margin - uint256(-pnl)); // 注意：亏损时, pnl为负数
        }
    }

    // 清算头寸， 清算的逻辑和关闭头寸类似，不过利润由清算用户获取
    // 注意： 清算人不能是自己，同时设置一个清算条件，例如亏损大于保证金的 80%
    function liquidatePosition(address _user) external {
        require(msg.sender != _user, "can't liquidate yourself");
        PositionInfo memory position = positions[_user];
        require(position.position != 0, "No open position");
        int256 pnl = calculatePnL(_user);

        // 检查是否需要清算，亏损大于保证金的 80%触发清算
        require(pnl < -int256(position.margin * 80 / 100), "can't liquidate now"); // 注意：亏损时, pnl为负数

        int256 USDCNow; // 当前仓位价值
        // 进行清算, 更新vETHAmount和vUSDCAmount
        if (position.position > 0) {
            uint256 USDCAmountLast = vUSDCAmount;
            vETHAmount = vETHAmount + uint256(position.position);
            vUSDCAmount = vK / vETHAmount;
            USDCNow = int256(USDCAmountLast) - int256(vUSDCAmount);
        } else {
            uint256 USDCAmountLast = vUSDCAmount;
            vETHAmount = vETHAmount - uint256(-position.position); // 此时的position.position为负数
            vUSDCAmount = vK / vETHAmount;
            USDCNow = int256(vUSDCAmount) - int256(USDCAmountLast);
        }
        int256 pnlNow = USDCNow - int256(position.margin) - int256(position.borrowed);
        // 计算清算奖励 = 用户保证金 - 亏损金额
        uint256 liquidationReward = position.margin - uint256(-pnlNow); // 此时的pnlNow为负数
        // 给清算人转账奖励
        USDC.transfer(msg.sender, liquidationReward);

        // 清除仓位信息
        delete positions[_user];
    }

    // 计算盈亏： 对比当前的仓位和借的 vUSDC
    function calculatePnL(address user) public view returns (int256) {
        PositionInfo memory position = positions[user];
        require(position.position != 0, "No open position");
        int256 USDCNow; // 当前仓位价值
        if (position.position > 0) {
            // 计算当前仓位价值
            uint256 USDCAmount = vK / (vETHAmount + uint256(position.position));
            USDCNow = int256(vUSDCAmount) - int256(USDCAmount);
        } else {
            uint256 USDCAmount = vK / (vETHAmount - uint256(-position.position)); // 此时的position.position为负数
            USDCNow = int256(USDCAmount) - int256(vUSDCAmount);
        }
        // 当前盈亏 = 当前仓位价值 - 保证金 - 借入的资金
        return USDCNow - int256(position.margin) - int256(position.borrowed);
    }
}
