// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";

contract IDO is Ownable {
    IERC20 public immutable token; // 代表将要出售的ERC20代币
    uint256 public immutable totalSupply; // 代币预售总量
    uint256 public immutable targetEth; // 募集eth目标
    uint256 public immutable limitEth; // 超募上限
    uint256 public immutable price; // 预售价格，以wei为单位
    uint256 public immutable endTime; // 预售结束的时间戳
    uint256 public totalEth; // 已募集的eth
    mapping(address => uint256) public balances; // 募集用户的存款金额

    event TokenSaled(address indexed user, uint256 amount); // 用户买入事件

    constructor(IERC20 _token, uint256 _totalSupply, uint256 _targetEth, uint256 _limitEth, uint256 _price, uint256 _duration) Ownable(msg.sender) {
        token = _token;
        totalSupply = _totalSupply;
        targetEth = _targetEth;
        limitEth = _limitEth;
        price = _price;
        endTime = block.timestamp + _duration;
        totalEth = 0;
    }

    modifier onlySuccess() {
        require(block.timestamp > endTime && totalEth >= targetEth);
        _;
    }

    modifier onlyFailed() {
        require(block.timestamp > endTime && totalEth < targetEth);
        _;
    }

    modifier onlyActive() {
        require(block.timestamp < endTime && totalEth < limitEth);
        _;
    }

    // 预售，募资
    function presale() external payable onlyActive {
        totalEth += msg.value;
        balances[msg.sender] += msg.value;
        emit TokenSaled(msg.sender, msg.value);
    }

    // 募资成功后，用户领取代币
    function claim() external onlySuccess {
        uint256 give = totalSupply * balances[msg.sender] / totalEth;
        balances[msg.sender] = 0;
        token.transfer(msg.sender, give);
    }

    // 募资成功后，项目方可以提现Eth
    function withdraw() external onlySuccess onlyOwner {
        (bool success, ) = msg.sender.call{value: address(this).balance}("");
        require(success, "withdraw failed");
    }

    // 募资失败，用户领回退款
    function refund() external onlyFailed {
        uint256 amount = balances[msg.sender];
        balances[msg.sender] = 0;
        (bool success, ) = msg.sender.call{value: amount}("");
        require(success, "refund failed");
    }

    // 募资失败，项目方领回代币
    function ownerRefund() external onlyOwner onlyFailed {
        bool success = token.transfer(msg.sender, token.balanceOf(address(this)));
        require(success, "ownerRefund failed");
    }
}
