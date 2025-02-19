// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {NFTMarket} from "../../../src/W2/D1/NFTMarket.sol";
import {BaseERC20WithCallBack} from "../../../src/W2/D1/BaseERC20WithCallBack.sol";
import {MyERC721} from "../../../src/W2/D1/MyERC721.sol";
import {Test} from "forge-std/Test.sol";

/**
要求测试内容：

1. 上架NFT：测试上架成功和失败情况，要求断言错误信息和上架事件。
2. 购买NFT：测试购买成功、自己购买自己的NFT、NFT被重复购买、支付Token过多或者过少情况，要求断言错误信息和购买事件。
3. 模糊测试：测试随机使用 0.01-10000 Token价格上架NFT，并随机使用任意Address购买NFT
「可选」不可变测试：测试无论如何买卖，NFTMarket合约中都不可能有 Token 持仓
 */
contract NFTMarketTest is Test {
    NFTMarket public nftMarket;
    BaseERC20WithCallBack public token;
    MyERC721 public nft;


    function setUp() public {
        token = new BaseERC20WithCallBack();
        nft = new MyERC721();
        nftMarket = new NFTMarket(token, nft);
    }

    // 测试NFT拥有者正常上架NFT
    function testList() public {
        address owner = makeAddr("Owner");
        nft.mint(owner, "ifps://1");

        vm.expectEmit(true, true, true, true, address(nftMarket));
        emit NFTMarket.NFTListed(1, owner, 10000);

        vm.prank(owner);
        nftMarket.list(1, 10000);

        (address seller, uint256 price, bool isActive) = nftMarket.listings(1);
        assertEq(seller, owner);
        assertEq(price, 10000);
        assertEq(isActive, true);
    }

    // 测试非NFT拥有者不能上架NFT
    function testListWhenNotOwner() public {
        address owner = makeAddr("Owner");
        address notOwner = makeAddr("NotOwner");

        nft.mint(owner, "ifps://1");

        vm.expectRevert("Not the owner");
        vm.prank(notOwner);
        nftMarket.list(1, 10000);
    }

    // 测试上架NFT价格不能为0
    function testListWhenPriceIsZero() public {
        address owner = makeAddr("Owner");
        nft.mint(owner, "ifps://1");

        vm.expectRevert("Price must be greater than zero");
        vm.prank(owner);
        nftMarket.list(1, 0);
    }
    
    // 测试已上架的NFT不能重复上架
    function testListWhenNFTIsAlreadyListed() public {
        address owner = makeAddr("Owner");
        nft.mint(owner, "ifps://1");
        vm.prank(owner);
        nftMarket.list(1, 10000);

        vm.expectRevert("NFT already listed");
        vm.prank(owner);
        nftMarket.list(1, 10000);
    }

    // 测试买方正常购买NFT
    function testBuy() public {
        address owner = makeAddr("Owner");
        address buyer = makeAddr("Buyer");

        // 铸造并上架NFT
        nft.mint(owner, "ifps://1");
        vm.startPrank(owner);
        nftMarket.list(1, 10000);

        // 授权nftMarket合约可以操作NFT
        nft.approve(address(nftMarket), 1);
        vm.stopPrank();

        // 给买方重置token余额
        deal(address(token), buyer, 10000);

        // 买方购买NFT
        vm.startPrank(buyer);
        token.approve(address(nftMarket), 10000);
        vm.expectEmit(true, true, true, true, address(nftMarket));
        emit NFTMarket.NFTSold(1, owner, buyer, 10000);
        nftMarket.buyNFT(1);
        vm.stopPrank();

        // 断言NFT已转移给买方，且nftMarket合约中NFT已下架
        (address seller, uint256 price, bool isActive) = nftMarket.listings(1);
        assertEq(seller, address(0));
        assertEq(price, 0);
        assertEq(isActive, false);
        
        // 断言买卖双方token余额是否正确转移，且nftMarket合约中没有token持仓
        assertEq(token.balanceOf(buyer), 0);
        assertEq(token.balanceOf(address(nftMarket)), 0);
        assertEq(token.balanceOf(owner), 10000);
        
    }

    // 测试买方不能购买自己的NFT
    function testBuyMyNFT() public {
        address owner = makeAddr("Owner");
        nft.mint(owner, "ifps://1");

        vm.startPrank(owner);
        nftMarket.list(1, 10000);
        vm.expectRevert("Seller cannot buy their own NFT");
        nftMarket.buyNFT(1);
        vm.stopPrank();
    }

    // 测试NFT被重复购买
    function testBuyWhenNFTIsAlreadySold() public {
        address owner = makeAddr("Owner");
        address buyer = makeAddr("Buyer");
        
        // 铸造并上架NFT
        nft.mint(owner, "ifps://1");
        vm.startPrank(owner);
        nftMarket.list(1, 10000);

        // 授权nftMarket合约可以操作NFT
        nft.approve(address(nftMarket), 1);
        vm.stopPrank();

        // 给买方重置token余额
        deal(address(token), buyer, 10000);

        // 买方购买NFT
        vm.startPrank(buyer);
        token.approve(address(nftMarket), 100000);
        vm.expectEmit(true, true, true, true, address(nftMarket));
        emit NFTMarket.NFTSold(1, owner, buyer, 10000);
        nftMarket.buyNFT(1);

        // 重复购买NFT
        vm.expectRevert("NFT not listed for sale");
        nftMarket.buyNFT(1);
        vm.stopPrank();
        
    }

    // 测试买方购买NFT时，使用token不足
    function testBuyWhenTokenBalanceIsNotEnough() public {
        address owner = makeAddr("Owner");
        address buyer = makeAddr("Buyer");
        
        // 铸造并上架NFT
        nft.mint(owner, "ifps://1");
        vm.startPrank(owner);
        nftMarket.list(1, 100000);

        // 授权nftMarket合约可以操作NFT
        nft.approve(address(nftMarket), 1);
        vm.stopPrank();

        // 给买方重置token余额，此时token余额不足购买NFT
        deal(address(token), buyer, 10000);

        // 买方购买NFT
        vm.startPrank(buyer);
        token.approve(address(nftMarket), 100000);
        vm.expectRevert("Insufficient token balance");
        nftMarket.buyNFT(1);
        vm.stopPrank();
    }

    // 模糊测试：测试随机使用 0.01-10000 Token价格上架NFT，并随机使用任意Address购买NFT
    function testFuzzBuy(uint256 price, address buyer) public {
        address owner = makeAddr("Owner");
        vm.assume(price > 0 && price <= 10000);
        // 确保买方不是0地址，也不是当前合约或已有合约地址或NFT拥有者地址
        vm.assume(buyer != address(0) 
            && buyer != address(this) 
            && buyer != address(nft) 
            && buyer != address(token)
            && buyer != address(nftMarket)
            && buyer != address(0x7109709ECfa91a80626fF3989D68f67F5b1DD12D) // 这个是Test合约地址，不会变
            && buyer != owner);

        nft.mint(owner, "ifps://1");

        vm.startPrank(owner);
        nftMarket.list(1, price);
        // 授权nftMarket合约可以操作NFT
        nft.approve(address(nftMarket), 1);
        vm.stopPrank();

        // 给买方重置token余额
        deal(address(token), buyer, price);

        // 买方购买NFT
        vm.startPrank(buyer);
        token.approve(address(nftMarket), price);
        vm.expectEmit(true, true, true, true, address(nftMarket));
        emit NFTMarket.NFTSold(1, owner, buyer, price);
        nftMarket.buyNFT(1);
        vm.stopPrank();

        // 断言NFT已转移给买方，且nftMarket合约中NFT已下架
        (address seller, uint256 nftPrice, bool isActive) = nftMarket.listings(1);
        assertEq(seller, address(0));
        assertEq(nftPrice, 0);
        assertEq(isActive, false);
        
        // 断言买卖双方token余额是否正确转移，且nftMarket合约中没有token持仓
        assertEq(token.balanceOf(buyer), 0);
        assertEq(token.balanceOf(address(nftMarket)), 0);
        assertEq(token.balanceOf(owner), price);
    }
}
