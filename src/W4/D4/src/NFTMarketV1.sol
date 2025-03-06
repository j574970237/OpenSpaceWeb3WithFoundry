// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import {ECDSA} from "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {IERC721} from "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import {Initializable} from "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import {OwnableUpgradeable} from "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";

// 可升级合约V1版本
contract NFTMarketV1 is Initializable, OwnableUpgradeable {
    address public constant ETH_FLAG = address(0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE);
    mapping(bytes32 => SellOrder) public listingOrders; // orderId -> SellOrder
    mapping(address => mapping(uint256 => bytes32)) private _lastIds; //  nft合约地址 -> NFT tokenId -> lastOrderId订单号

    uint256 private whiteListIndex; // 授权用户index,每次授权递增
    mapping(address => mapping(address => uint256)) public whiteListSigners; // 白名单用户地址  -> nft合约地址 -> 授权用户index
    bytes32 public constant DOMAIN_TYPE_HASH =
        keccak256("EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)");
    bytes32 constant WL_TYPEHASH = keccak256("IsWhiteList(address user, address nft)");
    bytes32 constant OFFLINE_TYPEHASH = keccak256("OfflineList(address seller, address nft, uint256 tokenId, address payToken, uint256 price, uint256 deadline)");

    function initialize() public initializer {
        __Ownable_init(msg.sender);
        whiteListIndex = 1; // 0值会作为判断条件，表示无效
    }

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
    event SetWhiteListSigner(address signer);

    // 上架
    function list(address nft, uint256 tokenId, address payToken, uint256 price, uint256 deadline) external {
        _list(msg.sender, nft, tokenId, payToken, price, deadline);
    }

    function _list(address seller, address nft, uint256 tokenId, address payToken, uint256 price, uint256 deadline) private {
        require(deadline > block.timestamp, "MKT: deadline is in the past");
        require(price > 0, "MKT: Price must be greater than zero");
        require(payToken == ETH_FLAG || IERC20(payToken).totalSupply() > 0, "MKT: payToken is not valid");
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

    // 购买 NFT
    function buyNFT(bytes32 orderId, bytes calldata signatureForWL) external payable {
        SellOrder memory order = listingOrders[orderId];
        // 检查订单上架状态以及是否超过deadline
        require(order.seller != address(0), "MKT: order not listed");
        require(order.deadline > block.timestamp, "MKT: order expired");
        _checkWL(signatureForWL, order.nft);

        // 更新状态前移除订单信息
        delete listingOrders[orderId];

        // 转移 NFT 给买家
        IERC721(order.nft).safeTransferFrom(order.seller, msg.sender, order.tokenId);
        // 转移代币给卖家
        _transferToken(order.payToken, order.seller, order.price);

        emit NFTSold(orderId, msg.sender);
    }

    // 代币转移，支持eth和ERC20
    function _transferToken(address token, address to, uint256 amount) private {
        // eth支付
        if (token == ETH_FLAG) {
            require(msg.value == amount, "MKT: wrong eth value");
            (bool success,) = to.call{value: amount}("");
            require(success, "MKT: transfer failed");
        } else { // 处理ERC20代币
            require(msg.value == 0, "MKT: wrong eth value");
            SafeERC20.safeTransferFrom(IERC20(token), msg.sender, to, amount);
        }
    }

    // 检查买家是否为某个NFT的白名单用户
    function _checkWL(bytes calldata signature, address nft) private view {
        bytes32 wlHash = _hashTypedData(keccak256(abi.encode(WL_TYPEHASH, msg.sender, nft)));
        address signer = ECDSA.recover(wlHash, signature);
        require(whiteListSigners[signer][nft] != 0, "MKT: not whiteListSigner");
    }

    // 设置某个NFT的白名单用户
    function setWhiteListSigner(address signer, address nft) external onlyOwner {
        require(signer != address(0), "MKT: zero address");
        require(whiteListSigners[signer][nft] != 0, "MKT: repeat set");
        whiteListSigners[signer][nft] = whiteListIndex;
        whiteListIndex++;
    }

    // 取消某个NFT的白名单用户
    function cancelWhiteListSigner(address signer, address nft) external onlyOwner {
        require(whiteListSigners[signer][nft] != 0, "MKT: signer is already not the whiteListSigner");
        delete whiteListSigners[signer][nft];
    }

    function _hashTypedData(bytes32 structHash) internal view returns (bytes32) {
        return keccak256(abi.encodePacked("\x19\x01", _domainSeparator(), structHash));
    }
    function _domainSeparator() internal view returns (bytes32) {
        return keccak256(abi.encode(
            DOMAIN_TYPE_HASH,
            keccak256(bytes("JJNFTMarket")),
            keccak256(bytes("1")),
            block.chainid,
            address(this)
        ));
    }
}
