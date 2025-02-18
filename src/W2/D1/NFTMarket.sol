// SPDX-License-Identifier: MIT 
pragma solidity ^0.8.0;

import "./BaseERC20WithCallBack.sol";
import "./MyERC721.sol";
/**
题目：
编写一个简单的 NFTMarket 合约，使用自己发行的ERC20 扩展 Token 来买卖 NFT，NFTMarket 的函数有：
1. list() : 实现上架功能，NFT 持有者可以设定一个价格（需要多少个 Token 购买该 NFT）并上架 NFT 到 NFTMarket，上架之后，其他人才可以购买。
2. buyNFT() : 普通的购买 NFT 功能，用户转入所定价的 token 数量，获得对应的 NFT。
3. 实现ERC20 扩展 Token 所要求的接收者方法 tokensReceived  ，在 tokensReceived 中实现NFT 购买功能。
 */
contract NFTMarket is ITokenReceiver {
    struct Listing {
        address seller;
        uint256 price;
    }

    BaseERC20WithCallBack public token;
    MyERC721 public nft;
    mapping(uint256 => Listing) public listings;
    // token address => user address => amount
    mapping(address => mapping(address => uint256)) public balances;

    constructor(BaseERC20WithCallBack _token, MyERC721 _nft) {
        token = _token;
        nft = _nft;
    }

    // 上架功能
    function list(uint256 tokenId, uint256 price) public {
        require(nft.ownerOf(tokenId) == msg.sender, "Not the owner");
        require(price > 0, "Price must be greater than zero");

        listings[tokenId] = Listing({
            seller: msg.sender,
            price: price
        });
        // 卖方将 NFT 转移到 NFTMarket 合约
        nft.transferFrom(listings[tokenId].seller, address(this), tokenId);
    }

    // 购买 NFT 功能
    function buyNFT(uint256 tokenId) public {
        Listing memory listing = listings[tokenId];
        require(listing.price > 0, "NFT not listed for sale");

        delete listings[tokenId];

        // 买方先把token转入NFT合约，合约balances记录此次存款
        require(token.transferWithCallback(msg.sender, address(this), listing.price), "Token transfer to NFTMarket failed");
        // 合约收到钱后再转给卖家
        require(token.transfer(listing.seller, listing.price), "Token transfer to seller failed");
        nft.safeTransferFrom(address(this), msg.sender, tokenId);
    }

    // 实现 ERC20 扩展 Token 所要求的接收者方法 tokensReceived
    function tokensReceived(address from, uint256 amount) external returns (bool) {
        // 调用限制
        require(msg.sender == address(token), "Only token contract can call this function");
        balances[address(token)][from] += amount;
        return true;
    }
}