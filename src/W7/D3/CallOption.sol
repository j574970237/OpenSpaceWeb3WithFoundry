// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract CallOption is ERC20, Ownable {
    struct OptionInfo {
        uint256 strikePrice; // 行权价格(以USDC计算)
        uint256 expiration; // 行权日期
        uint256 optionPrice; // 期权价格(以USDC计算)
    }

    OptionInfo public optionInfo;
    IERC20 public immutable usdc;
    bool public closed = false; // 期权关闭标识, 项目方进行赎回操作时将关闭此期权

    constructor(string memory _name, string memory _symbol, uint256 _strikePrice, uint256 _expiration, uint256 _optionPrice, IERC20 _usdc) 
        ERC20(_name, _symbol) Ownable(msg.sender) {
            require(_expiration > block.timestamp, "Expiration must be in the future");
            optionInfo = OptionInfo({strikePrice: _strikePrice, expiration: _expiration, optionPrice: _optionPrice});
            usdc = _usdc;
    }

    // 项目方根据转入的标的（ETH）发行期权 Token
    function issueOptions() external payable onlyOwner {
        _mint(address(this), msg.value); // 一份期权代表1个ETH，因此用户传入几个ETH就发行几份期权 Token
    }

    // 购买一份期权
    function buyOption(uint256 amount) external {
        require(amount == optionInfo.optionPrice, "input amount not equal to option price");
        require(usdc.transferFrom(msg.sender, owner(), amount), "Transfer USDC failed");
        require(balanceOf(address(this)) >= 1 * 1e18, "Not enough option");
        _transfer(address(this), msg.sender, 1 * 1e18);
    }

    // 行权一份期权, 在到期日当天，可通过指定的价格兑换出标的资产，并销毁期权Token
    function exerciseOption(uint256 amount) external {
        require(block.timestamp >= optionInfo.expiration, "Not expired yet");
        require(!closed, "option is closed"); // 项目方到期已赎回, 无法行权
        require(amount == optionInfo.strikePrice, "input amount not equal to strike price");
        // 销毁期权Token
        _burn(msg.sender, 1 * 1e18);
        // 用户通过指定的价格兑换出标的资产
        require(usdc.transferFrom(msg.sender, owner(), amount), "Transfer USDC failed");
        payable(msg.sender).transfer(1 ether);
    }

    // 销毁所有期权Token 赎回标的
    function redeemETH() external onlyOwner {
        // 设定项目方在行权日期后3天可进行赎回操作
        require(block.timestamp >= (optionInfo.expiration + 3 days), "Not expired yet");
        closed = true;
        _burn(address(this), balanceOf(address(this)));
        payable(owner()).transfer(address(this).balance);
    }
}
