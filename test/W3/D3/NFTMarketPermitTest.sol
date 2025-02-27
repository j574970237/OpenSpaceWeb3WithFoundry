// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {JJNFTPermit} from "../../../src/W3/D3/JJNFTPermit.sol";
import {JJTokenPermit} from "../../../src/W3/D3/JJTokenPermit.sol";
import {NFTMarketPermit} from "../../../src/W3/D3/NFTMarketPermit.sol";
import {Test} from "forge-std/Test.sol";

contract NFTMarketPermitTest is Test {
    JJTokenPermit public token;
    JJNFTPermit public nft;
    NFTMarketPermit public nftMarket;
    address public marketOwner;
    uint256 public marketOwnerKey;
    // EIP712 相关常量
    bytes32 public constant TOEKN_PERMIT_TYPEHASH = 
        keccak256("Permit(address owner,address spender,uint256 value,uint256 nonce,uint256 deadline)");
    bytes32 private constant NFT_PERMIT_TYPEHASH = 
        keccak256("Permit(address owner,address spender,uint256 tokenId,uint256 nonce,uint256 deadline)");
    bytes32 private constant MARKET_PERMIT_TYPEHASH =
        keccak256("NFTMarketPermit(address owner,address buyer,uint256 tokenId,uint256 nonce,uint256 deadline)");
    bytes32 private constant DOMAIN_TYPE_HASH =
        keccak256("EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)");
    bytes32 public TOKEN_DOMAIN_SEPARATOR;
    bytes32 public NFT_DOMAIN_SEPARATOR;
    bytes32 public MARKET_DOMAIN_SEPARATOR;

    function setUp() public {
        (marketOwner, marketOwnerKey) = makeAddrAndKey("MarketOwner");
        token = new JJTokenPermit();
        nft = new JJNFTPermit();
        vm.prank(marketOwner);
        nftMarket = new NFTMarketPermit(token, nft);

        TOKEN_DOMAIN_SEPARATOR = keccak256(
            abi.encode(DOMAIN_TYPE_HASH, keccak256(bytes("JJTokenPermit")), keccak256(bytes("1")), block.chainid, address(token)));
        NFT_DOMAIN_SEPARATOR = keccak256(
            abi.encode(DOMAIN_TYPE_HASH, keccak256(bytes(nft.name())), keccak256(bytes("1")), block.chainid, address(nft))
        );
        MARKET_DOMAIN_SEPARATOR = keccak256(
            abi.encode(DOMAIN_TYPE_HASH, keccak256(bytes("NFTMarketPermit")), keccak256(bytes("1")), block.chainid, nftMarket.getMarketOwner())
        );
    }

    function testPermitNFT() public {
        // alice作为卖方，bob作为买方
        (address alice, uint256 aliceKey) = makeAddrAndKey("Alice");
        (address bob, uint256 bobKey) = makeAddrAndKey("Bob");

        // 给alice mint测试NFT
        nft.mint(alice, "ifps://1");
        // 给alice一定量的测试token
        deal(address(token), alice, 1000000000);
        // 给bob一定量的测试token
        deal(address(token), bob, 1000000000);
        uint256 tokenId = 1;
        uint256 value = 1000000000;
        uint256 deadline = block.timestamp + 1 days;

        // 构建NFTMarket项目方授权给用户的购买权利签名
        (uint8 v1, bytes32 r1, bytes32 s1) = _getMarketPermitSignature(bob, tokenId, deadline);

        // 构建NFT上架permit签名
        (uint8 v2, bytes32 r2, bytes32 s2) = _getNFTPermitSignature(alice, aliceKey, address(nftMarket), tokenId, value, deadline);

        // 构建bob授权给NFTMarket操作token的签名
        (uint8 v3, bytes32 r3, bytes32 s3) = _getTokenPermitSignature(bob, bobKey, address(nftMarket), value, deadline);

        vm.expectEmit(true, true, true, true, address(nftMarket));
        emit NFTMarketPermit.NFTSold(tokenId, alice, bob, value);
        // 调用permitBuy方法进行购买
        vm.prank(bob);
        nftMarket.permitBuy(alice, address(nftMarket), tokenId, value, deadline, v1, r1, s1, deadline, v2, r2, s2, deadline, v3, r3, s3);

        // 断言买卖双方token余额是否正确转移，且nftMarket合约中没有token持仓
        assertEq(token.balanceOf(alice), 2000000000);
        assertEq(token.balanceOf(address(nftMarket)), 0);
        assertEq(token.balanceOf(bob), 0);
        // 断言NFT的拥有者为bob
        assertEq(nft.ownerOf(tokenId), bob);
    }

    // 生成市场许可签名
    function _getMarketPermitSignature(
        address buyer,
        uint256 tokenId,
        uint256 deadline
    ) internal view returns (uint8 v, bytes32 r, bytes32 s) {
        bytes32 structHash = keccak256(
            abi.encode(MARKET_PERMIT_TYPEHASH, nftMarket.getMarketOwner(), buyer, tokenId, nftMarket.getNonce(), deadline)
        );
        bytes32 digest = keccak256(abi.encodePacked("\x19\x01", MARKET_DOMAIN_SEPARATOR, structHash));
        return vm.sign(marketOwnerKey, digest);
    }

    // 生成NFT许可签名
    function _getNFTPermitSignature(
        address owner,
        uint256 ownerKey,
        address spender,
        uint256 tokenId,
        uint256 value,
        uint256 deadline
    ) internal view returns (uint8 v, bytes32 r, bytes32 s) {
        bytes32 structHash = keccak256(
            abi.encode(NFT_PERMIT_TYPEHASH, owner, spender, tokenId, value, tokenId, deadline)
        );
        bytes32 digest = keccak256(abi.encodePacked("\x19\x01", NFT_DOMAIN_SEPARATOR, structHash));
        return vm.sign(ownerKey, digest);
    }

    // 生成Token许可签名
    function _getTokenPermitSignature(
        address owner,
        uint256 ownerKey,
        address spender,
        uint256 value,
        uint256 deadline
    ) internal view returns (uint8 v, bytes32 r, bytes32 s) {
        uint256 nonce = token.nonces(owner);
        bytes32 structHash = keccak256(
            abi.encode(TOEKN_PERMIT_TYPEHASH, owner, spender, value, nonce, deadline)
        );
        bytes32 digest = keccak256(abi.encodePacked("\x19\x01", TOKEN_DOMAIN_SEPARATOR, structHash));
        return vm.sign(ownerKey, digest);
    }
}