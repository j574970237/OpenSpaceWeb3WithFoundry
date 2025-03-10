// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {IERC721} from "@openzeppelin/contracts/token/ERC721/IERC721.sol";

contract NFTMarket {
    address public constant ETH_FLAG = address(0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE);
    address public immutable owner; // 市场合约拥有者（部署者）
    uint256 private whiteListIndex;
    mapping(address => uint256) public whiteList; // 后端client地址 -> index

    constructor() {
        owner = msg.sender;
        whiteListIndex = 1; // 0值会作为判断条件，表示无效
    }

    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }

    // 购买 NFT，校验逻辑通过后端离线验证，链上只做资产(NFT和Token)转移，用户需要提前授权给NFTMarket相应转移权限即可
    function buyNFTForOffline(address buyer, address seller, address nft, uint256 tokenId, address payToken, uint256 price) external payable {
        // 验证调用方是否为白名单用户
        require(whiteList[msg.sender] != 0, "MKT: not whiteList client");
        // 转移 NFT 给买家
        IERC721(nft).safeTransferFrom(seller, buyer, tokenId);
        // 转移代币给卖家
        _transferToken(payToken, buyer, seller, price);
    }

    // 代币转移，支持ETH和ERC20代币
    function _transferToken(address token, address from, address to, uint256 amount) private {
        // eth支付
        if (token == ETH_FLAG) {
            require(msg.value == amount, "MKT: wrong eth value");
            (bool success,) = to.call{value: amount}("");
            require(success, "MKT: transfer failed");
        } else { // 处理ERC20代币
            require(msg.value == 0, "MKT: wrong eth value");
            SafeERC20.safeTransferFrom(IERC20(token), from, to, amount);
        }
    }

    // 设置白名单用户
    function setWhiteList(address client) external onlyOwner {
        require(client != address(0), "MKT: zero address");
        require(whiteList[client] == 0, "MKT: repeat set");
        whiteList[client] = whiteListIndex;
        whiteListIndex++;
    }

    // 取消白名单用户
    function cancelWhiteListSigner(address client) external onlyOwner {
        require(whiteList[client] != 0, "MKT: signer is already not the whiteListSigner");
        delete whiteList[client];
    }

}
