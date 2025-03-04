// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {Test} from "forge-std/Test.sol";
import {TokenBankPermit2} from "../../../../src/W4/D1/permit2/TokenBankPermit2.sol";
import {IPermit2} from "../../../../src/W4/D1/permit2/IPermit2.sol";
import {JJToken} from "../../../../src/W4/D1/permit2/JJToken.sol";

contract TokenBankPermit2Test is Test {
    bytes32 private constant _TYPE_HASH =
        keccak256("EIP712Domain(string name,uint256 chainId,address verifyingContract)");
    bytes32 private constant _HASHED_NAME = keccak256("Permit2");
    bytes32 public constant _TOKEN_PERMISSIONS_TYPEHASH = keccak256("TokenPermissions(address token,uint256 amount)");
    bytes32 public constant _PERMIT_TRANSFER_FROM_TYPEHASH = keccak256(
        "PermitTransferFrom(TokenPermissions permitted,address spender,uint256 nonce,uint256 deadline)TokenPermissions(address token,uint256 amount)"
    );

    TokenBankPermit2 public bank;
    IPermit2 public permit2;
    JJToken public token;
    address public owner;
    uint256 public ownerKey;

    function setUp() public {
        // 设置为本地测试网
        vm.chainId(31337);
        (owner, ownerKey) = makeAddrAndKey("owner");
        permit2 = IPermit2(0x90A3B384F62f43Ba07938EA43aEEc35c2aBfeCa2); // 本地测试网的permit2合约地址
        token = new JJToken();
        bank = new TokenBankPermit2(permit2);
        // 用户授权最大token限额给Permit2合约
        vm.prank(owner);
        token.approve(address(permit2), type(uint256).max);
    }

    function testDepositWithPermit2() public {
        uint256 amount = 1 * 1e18;
        deal(address(token), owner, amount);
        IPermit2.PermitTransferFrom memory permit = IPermit2.PermitTransferFrom({
            permitted: IPermit2.TokenPermissions({token: address(token), amount: amount}),
            nonce: bank.getNonceForPermit2(address(token), owner),
            deadline: block.timestamp + 1 days
        });
        bytes memory sig = _signPermit(permit, address(bank), ownerKey);
        vm.prank(owner);
        bank.depositWithPermit2(address(token), amount, permit.nonce, permit.deadline, sig);
        assertEq(bank.getBalance(address(token), owner), amount);
        assertEq(token.balanceOf(address(bank)), amount);
        assertEq(token.balanceOf(owner), 0);
    }

    // Generate a signature for a permit message.
    function _signPermit(IPermit2.PermitTransferFrom memory permit, address spender, uint256 signerKey)
        internal
        view
        returns (bytes memory sig)
    {
        (uint8 v, bytes32 r, bytes32 s) = vm.sign(signerKey, _getEIP712Hash(permit, spender));
        return abi.encodePacked(r, s, v);
    }

    function _getEIP712Hash(IPermit2.PermitTransferFrom memory permit, address spender) internal view returns (bytes32 h) {
        // 本地计算 DOMAIN_SEPARATOR
        bytes32 domainSeparator = keccak256(abi.encode(_TYPE_HASH, _HASHED_NAME, block.chainid, address(permit2)));
        bytes32 tokenPermissionsHash = _hashTokenPermissions(permit.permitted);
        bytes32 permitHash = keccak256(
            abi.encode(_PERMIT_TRANSFER_FROM_TYPEHASH, tokenPermissionsHash, spender, permit.nonce, permit.deadline)
        );
        return keccak256(abi.encodePacked("\x19\x01", domainSeparator, permitHash));
    }

    function _hashTokenPermissions(IPermit2.TokenPermissions memory permitted)
        private
        pure
        returns (bytes32)
    {
        return keccak256(abi.encode(_TOKEN_PERMISSIONS_TYPEHASH, permitted));
    }

}
