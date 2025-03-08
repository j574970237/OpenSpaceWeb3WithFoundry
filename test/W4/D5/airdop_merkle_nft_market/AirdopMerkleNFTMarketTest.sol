// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {Test} from "forge-std/Test.sol";
import "../../../../src/W4/D5/airdop_merkle_nft_market/contract/AirdopMerkleNFTMarket.sol";
import "../../../../src/W4/D5/airdop_merkle_nft_market/contract/JJNFT.sol";
import "../../../../src/W4/D5/airdop_merkle_nft_market/contract/JJTokenPermit.sol";

contract AirdopMerkleNFTMarketTest is Test {
    JJTokenPermit public token;
    JJNFT public nft;
    AirdopMerkleNFTMarket public nftMarket;
    bytes32 public merkleRoot;
    // EIP712 相关常量
    bytes32 private constant DOMAIN_TYPE_HASH =
        keccak256("EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)");
    bytes32 public constant TOEKN_PERMIT_TYPEHASH =
        keccak256("Permit(address owner,address spender,uint256 value,uint256 nonce,uint256 deadline)");
    bytes32 public TOKEN_DOMAIN_SEPARATOR;

    function setUp() public {
        token = new JJTokenPermit();
        nft = new JJNFT();
        // 根据已有白名单列表得到的默克尔树根
        merkleRoot = hex"5da9154bd78fea289d2ea6a69217e5ce01f7951bbd9abd06170366a953a6c245";
        nftMarket = new AirdopMerkleNFTMarket(merkleRoot);
        TOKEN_DOMAIN_SEPARATOR = keccak256(
            abi.encode(
                DOMAIN_TYPE_HASH,
                keccak256(bytes("JJTokenPermit")),
                keccak256(bytes("1")),
                block.chainid,
                address(token)
            )
        );
    }

    // 使用multicall测试白名单用户半价购买
    function testMultiCallWithWhiteListUser() public {
        // alice作为卖方，bob作为买方
        address alice = makeAddr("Alice");
        (address bob, uint256 bobKey) = makeAddrAndKey("Bob");

        // 给alice mint测试NFT
        nft.mint(alice, "ifps://1");
        // 给alice一定量的测试token
        deal(address(token), alice, 1000000000);
        // 给bob一定量的测试token
        deal(address(token), bob, 1000000000);

        // 构建卖单信息
        uint256 tokenId = 1;
        uint256 price = 1000000000;
        uint256 deadline = block.timestamp + 1 days;
        AirdopMerkleNFTMarket.SellOrder memory order = AirdopMerkleNFTMarket.SellOrder({
            seller: alice,
            nft: address(nft),
            tokenId: tokenId,
            payToken: address(token),
            price: price,
            deadline: deadline
        });
        // 根据卖单信息生成唯一的订单id
        bytes32 orderId = keccak256(abi.encode(order));
        // alice上架nft
        vm.startPrank(alice);
        // 授权NFT给NFTMarket
        nft.approve(address(nftMarket), tokenId);
        nftMarket.list(address(nft), tokenId, address(token), price, deadline);
        vm.stopPrank();

        // 构建bob授权给NFTMarket操作token的签名
        (uint8 v, bytes32 r, bytes32 s) = _getTokenPermitSignature(bob, bobKey, address(nftMarket), price, deadline);
        vm.startPrank(bob);
        // 编码permitPrePay函数调用
        bytes memory permitPrePayData =
            abi.encodeWithSelector(AirdopMerkleNFTMarket.permitPrePay.selector, orderId, v, r, s);

        // 编码claimNFT函数调用
        bytes32[] memory merkleProof = new bytes32[](2);
        merkleProof[0] = 0x2e01a89024029d366a0e5c53a3ba31264c481b3d774805b0b64268258b528895;
        merkleProof[1] = 0x4e2d5557ce6c7071e53654eb83c98a91597145261447de298270e861726fa18e;
        bytes memory claimNFTData =
            abi.encodeWithSelector(AirdopMerkleNFTMarket.claimNFT.selector, orderId, merkleProof);

        // 创建包含两个编码后函数调用的data数组
        bytes[] memory data = new bytes[](2);
        data[0] = permitPrePayData;
        data[1] = claimNFTData;
        // 使用 multicall一次性调用两个方法(permitPrePay和claimNFT)
        nftMarket.multicall(data);
        vm.stopPrank();

        // 断言买卖双方token余额是否正确转移，且nftMarket合约中没有token持仓
        assertEq(token.balanceOf(alice), 1500000000); // 白名单用户半价
        assertEq(token.balanceOf(address(nftMarket)), 0);
        assertEq(token.balanceOf(bob), 500000000);
        // 断言NFT的拥有者为bob
        assertEq(nft.ownerOf(tokenId), bob);
    }

    // 使用multicall测试非白名单用户全价购买
    function testMultiCallNotWhiteListUser() public {
        // alice作为卖方，sam作为买方
        address alice = makeAddr("Alice");
        (address sam, uint256 samKey) = makeAddrAndKey("Sam");

        // 给alice mint测试NFT
        nft.mint(alice, "ifps://1");
        // 给alice一定量的测试token
        deal(address(token), alice, 1000000000);
        // 给sam一定量的测试token
        deal(address(token), sam, 1000000000);

        // 构建卖单信息
        uint256 tokenId = 1;
        uint256 price = 1000000000;
        uint256 deadline = block.timestamp + 1 days;
        AirdopMerkleNFTMarket.SellOrder memory order = AirdopMerkleNFTMarket.SellOrder({
            seller: alice,
            nft: address(nft),
            tokenId: tokenId,
            payToken: address(token),
            price: price,
            deadline: deadline
        });
        // 根据卖单信息生成唯一的订单id
        bytes32 orderId = keccak256(abi.encode(order));
        // alice上架nft
        vm.startPrank(alice);
        // 授权NFT给NFTMarket
        nft.approve(address(nftMarket), tokenId);
        nftMarket.list(address(nft), tokenId, address(token), price, deadline);
        vm.stopPrank();

        // 构建sam授权给NFTMarket操作token的签名
        (uint8 v, bytes32 r, bytes32 s) = _getTokenPermitSignature(sam, samKey, address(nftMarket), price, deadline);
        vm.startPrank(sam);
        // 编码permitPrePay函数调用
        bytes memory permitPrePayData =
            abi.encodeWithSelector(AirdopMerkleNFTMarket.permitPrePay.selector, orderId, v, r, s);

        // 编码claimNFT函数调用
        bytes32[] memory merkleProof = new bytes32[](2);
        merkleProof[0] = 0x2e01a89024029d366a0e5c53a3ba31264c481b3d774805b0b64268258b528895;
        merkleProof[1] = 0x4e2d5557ce6c7071e53654eb83c98a91597145261447de298270e861726fa18e;
        bytes memory claimNFTData =
            abi.encodeWithSelector(AirdopMerkleNFTMarket.claimNFT.selector, orderId, merkleProof);

        // 创建包含两个编码后函数调用的data数组
        bytes[] memory data = new bytes[](2);
        data[0] = permitPrePayData;
        data[1] = claimNFTData;
        // 使用 multicall一次性调用两个方法(permitPrePay和claimNFT)
        nftMarket.multicall(data);
        vm.stopPrank();

        // 断言买卖双方token余额是否正确转移，且nftMarket合约中没有token持仓
        assertEq(token.balanceOf(alice), 2000000000); // 非白名单用户全价购买
        assertEq(token.balanceOf(address(nftMarket)), 0);
        assertEq(token.balanceOf(sam), 0);
        // 断言NFT的拥有者为sam
        assertEq(nft.ownerOf(tokenId), sam);
    }

    // 生成Token许可签名
    function _getTokenPermitSignature(address owner, uint256 ownerKey, address spender, uint256 value, uint256 deadline)
        internal
        view
        returns (uint8 v, bytes32 r, bytes32 s)
    {
        uint256 nonce = token.nonces(owner);
        bytes32 structHash = keccak256(abi.encode(TOEKN_PERMIT_TYPEHASH, owner, spender, value, nonce, deadline));
        bytes32 digest = keccak256(abi.encodePacked("\x19\x01", TOKEN_DOMAIN_SEPARATOR, structHash));
        return vm.sign(ownerKey, digest);
    }
}
