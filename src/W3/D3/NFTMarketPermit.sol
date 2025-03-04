// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {JJTokenPermit} from "../../../src/W3/D3/JJTokenPermit.sol";
import {JJNFTPermit} from "../../../src/W3/D3/JJNFTPermit.sol";
import {SafeERC20, IERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import {ITokenReceiver} from "./ITokenReceiver.sol";
import {ECDSA} from "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";

contract NFTMarketPermit {
    struct Listing {
        address seller;
        uint256 price;
        bool isActive; // 添加状态标识
    }

    JJTokenPermit public immutable token; // 添加 immutable 优化 gas
    JJNFTPermit public immutable nft;
    address private marketOwner; // NFTMarket合约拥有者(项目方)
    mapping(uint256 => Listing) public listings;

    uint256 private nonce;
    // EIP712 相关常量
    bytes32 public constant NFT_PERMIT_TYPEHASH =
        keccak256("Permit(address owner,address spender,uint256 tokenId,uint256 nonce,uint256 deadline)");
    bytes32 public constant MARKET_PERMIT_TYPEHASH =
        keccak256("NFTMarketPermit(address owner,address buyer,uint256 tokenId,uint256 nonce,uint256 deadline)");
    bytes32 public constant DOMAIN_TYPE_HASH =
        keccak256("EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)");

    // Events
    event NFTListed(uint256 indexed tokenId, address indexed seller, uint256 price);
    event NFTSold(uint256 indexed tokenId, address indexed seller, address indexed buyer, uint256 price);
    event NFTDelisted(uint256 indexed tokenId, address indexed seller);

    constructor(JJTokenPermit _token, JJNFTPermit _nft) {
        marketOwner = msg.sender;
        require(address(_token) != address(0), "Invalid token address");
        require(address(_nft) != address(0), "Invalid NFT address");
        token = _token;
        nft = _nft;
    }

    // 普通上架
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
        
        // 转移 NFT 给买家
        transferNFT(msg.sender, tokenId);
        // 转移代币给卖家
        uint256 sellerBalance = token.balanceOf(listing.seller);
        SafeERC20.safeTransferFrom(IERC20(token), msg.sender, listing.seller, listing.price);
        // 检查代币转移是否成功，不能盲目相信第三方合约的方法
        require(IERC20(token).balanceOf(listing.seller) == sellerBalance + listing.price, "Transfer token failed");

        emit NFTSold(tokenId, listing.seller, msg.sender, listing.price);
    }

    // 转移 NFT 给买家
    function transferNFT(address to, uint256 tokenId) internal {
        // 代码顺序： 数据校验 -> 数据更新 -> 数据处理（调用第三方合约）
        require(listings[tokenId].isActive, "NFT is not listed for sale");
        address owner = listings[tokenId].seller;
        // 清除上架信息
        delete listings[tokenId];

        nft.safeTransferFrom(owner, to, tokenId);
        
    }

    // 实现 ERC20 扩展 Token 的 tokensReceived 回调函数
    function tokensReceived(address _token, address from, uint256 amount, bytes calldata data) external returns (bool) {
        require(_token == address(token), "Only token contract can call");

        // 解码 data 获取 tokenId
        uint256 tokenId = abi.decode(data, (uint256));

        Listing memory listing = listings[tokenId];
        require(amount == listing.price, "Incorrect payment amount");

        uint256 sellerBalance = token.balanceOf(listing.seller);
        // 转移代币给卖家
        SafeERC20.safeTransfer(IERC20(token), listing.seller, amount);
        require(token.balanceOf(listing.seller) == sellerBalance + amount, "Transfer token failed");

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

    // 白名单用户购买NFT
    function permitBuy(address owner, uint256 tokenId, uint256 value,
        uint256 deadline1, uint8 v1, bytes32 r1, bytes32 s1,
        uint256 deadline2, uint8 v2, bytes32 r2, bytes32 s2,
        uint256 deadline3, uint8 v3, bytes32 r3, bytes32 s3) public {

        // 验证签名1，检查买家是否在白名单中
        permit(msg.sender, tokenId, deadline1, v1, r1, s1);
        // 验证签名2，调用NFT合约的permit方法检验卖家是否上架并授权给了Market操作NFT的权利
        nft.permit(nft.ownerOf(tokenId), address(this), tokenId, value, tokenId, deadline2, v2, r2, s2);
        // 验证签名3，调用token合约的permit方法检验买家是否授权给了Market操作代币的权利
        token.permit(msg.sender, address(this), value, deadline3, v3, r3, s3);

        // 转移NFT给买家
        nft.safeTransferFrom(owner, msg.sender, tokenId);
        // 转移代币给卖家
        uint256 sellerBalance = token.balanceOf(owner);
        SafeERC20.safeTransferFrom(IERC20(token), msg.sender, owner, value);
        require(token.balanceOf(owner) == sellerBalance + value, "Transfer token failed");

        emit NFTSold(tokenId, owner, msg.sender, value);
    }

    // 验证NFTMarket项目方授权给用户的购买权利
    function permit(
        address buyer,
        uint256 tokenId,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) public {
        require(block.timestamp <= deadline, "NFTMarket Permit expired");

        // 构建签名摘要
        bytes32 structHash = keccak256(abi.encode(MARKET_PERMIT_TYPEHASH, marketOwner, buyer, tokenId, nonce, deadline));
        nonce++;
        bytes32 digest = keccak256(abi.encodePacked("\x19\x01", DOMAIN_SEPARATOR(), structHash));

        // 验证签名
        address signer = ECDSA.recover(digest, v, r, s);
        require(signer == marketOwner, "Invalid signature");
    }

    function getMarketOwner() public view returns (address) {
        return marketOwner;
    }

    function getNonce() public view returns (uint256) {
        return nonce;
    }

    function DOMAIN_SEPARATOR() public view returns (bytes32) {
        return keccak256(abi.encode(DOMAIN_TYPE_HASH, keccak256(bytes("NFTMarketPermit")), keccak256(bytes("1")), block.chainid, marketOwner));
    }
}
