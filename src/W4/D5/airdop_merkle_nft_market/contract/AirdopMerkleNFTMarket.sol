// SPDX-License-Identifier: MIT 
pragma solidity ^0.8.20;

import {ERC20Permit} from "@openzeppelin/contracts/token/ERC20/extensions/ERC20Permit.sol";
import {SafeERC20, IERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import {IERC721} from "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import {MerkleProof} from "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";
import {Multicall} from "@openzeppelin/contracts/utils/Multicall.sol";
import {Address} from "@openzeppelin/contracts/utils/Address.sol";

contract AirdopMerkleNFTMarket {
    bytes32 public immutable merkleRoot;
    mapping(bytes32 => SellOrder) public listingOrders; // orderId -> SellOrder
    mapping(address => mapping(uint256 => bytes32)) private _lastIds; //  nft合约地址 -> NFT tokenId -> lastOrderId订单号

    struct SellOrder {
        address seller;
        address nft;
        uint256 tokenId;
        address payToken;
        uint256 price;
        uint256 deadline;
    }

    // Events
    event NFTListed(
        address indexed nft,
        uint256 indexed tokenId,
        bytes32 orderId,
        address seller,
        address payToken,
        uint256 price,
        uint256 deadline
    );
    event NFTSold(bytes32 orderId, address buyer);
    event Cancel(bytes32 orderId);
    event Claimed(address account);

    constructor(bytes32 merkleRoot_) {
        merkleRoot = merkleRoot_;
    }

    // 上架
    function list(address nft, uint256 tokenId, address payToken, uint256 price, uint256 deadline) external {
        _list(msg.sender, nft, tokenId, payToken, price, deadline);
    }

    function _list(address seller, address nft, uint256 tokenId, address payToken, uint256 price, uint256 deadline) private {
        require(deadline > block.timestamp, "MKT: deadline is in the past");
        require(price > 0, "MKT: Price must be greater than zero");
        require(IERC20(payToken).totalSupply() > 0, "MKT: payToken is not valid");
        require(IERC721(nft).ownerOf(tokenId) == seller, "MKT: Not owner");

        // 确保市场合约有此NFT的授权
        require(
            IERC721(nft).getApproved(tokenId) == address(this)
                || IERC721(nft).isApprovedForAll(seller, address(this)),
            "MKT: NFT not approved"
        );
        // 构建卖单信息
        SellOrder memory order = SellOrder({
            seller: seller,
            nft: nft,
            tokenId: tokenId,
            payToken: payToken,
            price: price,
            deadline: deadline
        });
        // 根据卖单信息生成唯一的订单id
        bytes32 orderId = keccak256(abi.encode(order));
        // 避免订单重复上架
        require(listingOrders[orderId].seller == address(0), "MKT: order already listed");
        // 记录订单信息
        listingOrders[orderId] = order;
        _lastIds[nft][tokenId] = orderId;
        emit NFTListed(nft, tokenId, orderId, seller, payToken, price, deadline);
    }

    // 返回指定NFT的订单id
    function listing(address nft, uint256 tokenId) external view returns (bytes32) {
        bytes32 id = _lastIds[nft][tokenId];
        return listingOrders[id].seller == address(0) ? bytes32(0x00) : id;
    }

    // 取消订单
    function cancel(bytes32 orderId) external {
        address seller = listingOrders[orderId].seller;
        // 安全检查：订单是否已上架，取消上架订单的必须是卖家
        require(seller != address(0), "MKT: order not listed");
        require(seller == msg.sender, "MKT: only seller can cancel");
        delete listingOrders[orderId];
        emit Cancel(orderId);
    }

    // 调用token的 permit 进行授权
    function permitPrePay(bytes32 orderId, uint8 v, bytes32 r, bytes32 s) external {
        SellOrder memory order = listingOrders[orderId];
        // 检查订单上架状态以及是否超过deadline
        require(order.seller != address(0), "MKT: order not listed");
        require(order.deadline > block.timestamp, "MKT: order expired");
        ERC20Permit(order.payToken).permit(msg.sender, address(this), order.price, order.deadline, v, r, s);
    }

    // 通过默克尔树验证白名单，购买NFT
    function claimNFT(bytes32 orderId, bytes32[] calldata merkleProof) external {
        SellOrder memory order = listingOrders[orderId];
        // 检查订单上架状态以及是否超过deadline
        require(order.seller != address(0), "MKT: order not listed");
        require(order.deadline > block.timestamp, "MKT: order expired");

        // 更新状态前移除订单信息
        delete listingOrders[orderId];

        // 通过默克尔树验证白名单
        bytes32 node = keccak256(abi.encodePacked(address(msg.sender)));
        // 白名单用户可以优惠 50% 的Token 来购买 NFT
        if (MerkleProof.verify(merkleProof, merkleRoot, node)) {
            SafeERC20.safeTransferFrom(IERC20(order.payToken), msg.sender, order.seller, (order.price / 2));
            emit Claimed(msg.sender);
        } else {
            SafeERC20.safeTransferFrom(IERC20(order.payToken), msg.sender, order.seller, order.price);
        }
        // 转移 NFT 给买家
        IERC721(order.nft).safeTransferFrom(order.seller, msg.sender, order.tokenId);
        emit NFTSold(orderId, msg.sender);
    }

    function multicall(bytes[] calldata data) external returns (bytes[] memory results) {
        results = new bytes[](data.length);
        for (uint256 i = 0; i < data.length; i++) {
            results[i] = Address.functionDelegateCall(address(this), data[i]);
        }
        return results;
    }
}