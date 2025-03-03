// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "forge-std/Test.sol";
import "../../../../src/W4/D1/create_factory/ERC20CreateFactory.sol";

contract ERC20CreateFactoryTest is Test {
    ERC20Factory factory;
    address public owner;
    address payable public projectWallet;
    uint256 public constant FEE_PERCENTAGE = 5; // 手续费百分比

    function setUp() public {
        owner = msg.sender;
        projectWallet = payable(address(0x1)); // 项目方钱包地址
        factory = new ERC20Factory(address(new MyToken()), FEE_PERCENTAGE, projectWallet);
    }

    function testDeployInscription() public {
        string memory name = "TEST";
        string memory symbol = "TEST";
        uint256 totalSupply = 100000; // 100000个代币
        uint256 perMint = 10; // 每次铸造10个代币
        uint256 price = 100 wei; // 铸造每个代币的价格

        vm.prank(owner); // 使用 prank 来模拟调用者
        address tokenAddress = factory.deployInscription(name, symbol, totalSupply, perMint, price);

        // 验证代币是否成功部署并且铸造价格是否正确设置
        assertTrue(tokenAddress != address(0));
        assertEq(factory.tokenToPrice(tokenAddress), price);
    }

    function testMintInscription() public {
        string memory name = "TEST2";
        string memory symbol = "TEST2";
        uint256 totalSupply = 1000;
        uint256 perMint = 1;
        uint256 price = 100 wei;

        vm.prank(owner);
        address tokenAddress = factory.deployInscription(name, symbol, totalSupply, perMint, price);

        uint256 initialBalance = ERC20Upgradeable(tokenAddress).balanceOf(owner);
        uint256 mintFee = (perMint * price * FEE_PERCENTAGE) / 100; // 计算手续费
        uint256 valueToSend = (perMint * price) + mintFee;

        vm.deal(owner, valueToSend); // 给调用者提供足够的 ETH 来支付费用
        vm.prank(owner);
        factory.mintInscription{value: valueToSend}(tokenAddress);

        // 验证铸造数量和费用
        assertEq(ERC20Upgradeable(tokenAddress).balanceOf(owner), (initialBalance + perMint) * 1e18);
        assertEq(projectWallet.balance, mintFee);
    }
}