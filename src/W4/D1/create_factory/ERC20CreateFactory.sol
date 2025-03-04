// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/proxy/Clones.sol";
import {MyToken, ERC20Upgradeable} from "./MyToken.sol";

contract ERC20Factory {
    address public implementation;
    uint256 public feePercentage; // 手续费百分比
    address payable public projectWallet; // 项目方钱包地址
    mapping(address => uint256) public tokenToPrice; // 存储每个代币的铸造价格

    event TokenDeployed(address indexed tokenAddress, string symbol, uint256 totalSupply);
    event TokensMinted(address indexed tokenAddress, address indexed minter, uint256 amount);

    constructor(address _implementation, uint256 _feePercentage, address payable _projectWallet) {
        implementation = _implementation;
        feePercentage = _feePercentage;
        projectWallet = _projectWallet;
    }

    // 创建 ERC20 Token合约
    function deployInscription(string memory name, string memory symbol, uint256 initialSupply, uint256 perMint, uint256 price) external returns (address) {
        address clone = Clones.clone(implementation);
        MyToken(clone).initialize(name, symbol, initialSupply, perMint);
        tokenToPrice[clone] = price; // 存储铸造价格
        emit TokenDeployed(clone, symbol, initialSupply);
        return clone;
    }

    // 调用发行创建时确定的 perMint 数量的 token，并收取相应的费用
    function mintInscription(address tokenAddr) external payable {
        MyToken token = MyToken(tokenAddr);
        uint256 price = tokenToPrice[tokenAddr];
        uint256 perMintPrice = token.perMint() * price;
        require(msg.value >= perMintPrice, "Insufficient payment");
        uint256 fee = (msg.value * feePercentage) / 100;
        uint256 remaining = msg.value - fee;
        
        // 使用 call 进行转账
        (bool success, ) = projectWallet.call{value: fee}("");
        require(success, "Failed to send Ether to project wallet");
        // 将剩余款项返回给用户
        (bool success2, ) = payable(msg.sender).call{value: remaining}("");
        require(success2, "Failed to send Ether to user");
        
        token.mint(msg.sender);
        emit TokensMinted(tokenAddr, msg.sender, token.perMint());
    }
}