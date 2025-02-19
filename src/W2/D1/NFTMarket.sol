// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./BaseERC20WithCallBack.sol";
import "./MyERC721.sol";
/**
 * 题目：
 * 编写一个简单的 NFTMarket 合约，使用自己发行的ERC20 扩展 Token 来买卖 NFT，NFTMarket 的函数有：
 * 1. list() : 实现上架功能，NFT 持有者可以设定一个价格（需要多少个 Token 购买该 NFT）并上架 NFT 到 NFTMarket，上架之后，其他人才可以购买。
 * 2. buyNFT() : 普通的购买 NFT 功能，用户转入所定价的 token 数量，获得对应的 NFT。
 * 3. 实现ERC20 扩展 Token 所要求的接收者方法 tokensReceived  ，在 tokensReceived 中实现NFT 购买功能。
 */

contract NFTMarket is ITokenReceiver {
    struct Listing {
        address seller;
        uint256 price;
        bool isActive; // 添加状态标识
    }

    BaseERC20WithCallBack public immutable token; // 添加 immutable 优化 gas
    MyERC721 public immutable nft;
    mapping(uint256 => Listing) public listings;

    // Events
    event NFTListed(uint256 indexed tokenId, address indexed seller, uint256 price);
    event NFTSold(uint256 indexed tokenId, address indexed seller, address indexed buyer, uint256 price);
    event NFTDelisted(uint256 indexed tokenId, address indexed seller);

    constructor(BaseERC20WithCallBack _token, MyERC721 _nft) {
        require(address(_token) != address(0), "Invalid token address");
        require(address(_nft) != address(0), "Invalid NFT address");
        token = _token;
        nft = _nft;
    }

    // 上架
    function list(uint256 tokenId, uint256 price) external {
        require(nft.ownerOf(tokenId) == msg.sender, "Not the owner");
        require(price > 0, "Price must be greater than zero");
        require(!listings[tokenId].isActive, "NFT already listed");

        listings[tokenId] = Listing({seller: msg.sender, price: price, isActive: true});

        emit NFTListed(tokenId, msg.sender, price);
    }

    // 购买 NFT
    function buyNFT(uint256 tokenId) external {
        Listing memory listing = listings[tokenId];
        require(listing.isActive, "NFT not listed for sale");
        require(msg.sender != listing.seller, "Seller cannot buy their own NFT");

        // 更新状态前进行所有检查
        require(token.balanceOf(msg.sender) >= listing.price, "Insufficient token balance");
        // 添加授权检查
        require(token.allowance(msg.sender, address(this)) >= listing.price, "Insufficient token allowance");

        // 转移 NFT 给买家
        transferNFT(msg.sender, tokenId);
        // 转移代币给卖家
        token.transferFrom(msg.sender, listing.seller, listing.price);

        emit NFTSold(tokenId, listing.seller, msg.sender, listing.price);
    }

    // 转移 NFT 给买家
    function transferNFT(address to, uint256 tokenId) internal {
        require(listings[tokenId].isActive, "NFT is not listed for sale");

        address owner = listings[tokenId].seller;
        nft.safeTransferFrom(owner, to, tokenId);
        
        // 清除上架信息
        delete listings[tokenId];
    }

    // 实现 ERC20 扩展 Token 的 tokensReceived 回调函数
    function tokensReceived(address from, uint256 amount, bytes calldata data) external override returns (bool) {
        require(msg.sender == address(token), "Only token contract can call");

        // 解码 data 获取 tokenId
        uint256 tokenId = abi.decode(data, (uint256));

        Listing memory listing = listings[tokenId];
        require(amount == listing.price, "Incorrect payment amount");

        // 转移代币给卖家
        token.transfer(listing.seller, amount);

        // 转移 NFT 给买家
        transferNFT(from, tokenId);

        emit NFTSold(tokenId, listing.seller, from, amount);

        return true;
    }

    // 查询 NFT 是否在售
    function isListed(uint256 tokenId) external view returns (bool) {
        return listings[tokenId].isActive;
    }

    // 查询 NFT 价格
    function getPrice(uint256 tokenId) external view returns (uint256) {
        require(listings[tokenId].isActive, "NFT not listed");
        return listings[tokenId].price;
    }
}
