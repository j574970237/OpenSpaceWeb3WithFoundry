// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {TokenBankPermit} from "../../../src/W3/D3/TokenBankPermit.sol";
import {JJTokenPermit} from "../../../src/W3/D3/JJTokenPermit.sol";
import {Test} from "forge-std/Test.sol";

contract TokenBankPermitTest is Test {
    TokenBankPermit public bank;
    JJTokenPermit public token;
    bytes32 public constant PERMIT_TYPEHASH = keccak256("Permit(address owner,address spender,uint256 value,uint256 nonce,uint256 deadline)");
    bytes32 public constant EIP712DOMAIN_TYPEHASH = keccak256("EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)");
    bytes32 public DOMAIN_SEPARATOR;

    struct EIP712Domain {
        string name;
        string version;
        uint256 chainId;
        address verifyingContract;
    }
    struct Permit {
        address owner;
        address spender;
        uint256 value;
        uint256 nonce;
        uint256 deadline;
    }

    function setUp() public {
        bank = new TokenBankPermit();
        token = new JJTokenPermit();
        DOMAIN_SEPARATOR = keccak256(abi.encode(EIP712DOMAIN_TYPEHASH, keccak256(bytes("JJTokenPermit")), keccak256(bytes("1")), block.chainid, address(token)));
    }

    function testPermitDeposit() public {
        (address alice, uint256 privateKey) = makeAddrAndKey("Alice");

        // 给alice一定量的测试token
        deal(address(token), alice, 1000000000);
        // 构建permit签名
        uint256 value = 1000000000;
        uint256 nonce = token.nonces(alice);
        uint256 deadline = block.timestamp + 1 days;
        bytes32 structHash = keccak256(abi.encode(PERMIT_TYPEHASH, alice, address(bank), value, nonce, deadline));
        bytes32 digest = keccak256(abi.encodePacked("\x19\x01", DOMAIN_SEPARATOR, structHash));
        (uint8 v, bytes32 r, bytes32 s) = vm.sign(privateKey, digest);

        vm.expectEmit(true, true, true, true, address(bank));
        emit TokenBankPermit.Deposit(alice, value);
        // 调用permitDeposit方法进行存款
        vm.prank(alice);
        bank.permitDeposit(address(token), alice, value, deadline, v, r, s);

        // 检查存款是否成功
        assertEq(bank.getBalance(address(token), alice), value);
        // 检查token余额是否减少
        assertEq(token.balanceOf(alice), 0);
        // 检查bank合约余额是否增加
        assertEq(token.balanceOf(address(bank)), value);
    }
}