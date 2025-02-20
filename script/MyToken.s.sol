// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {Script, console} from "forge-std/Script.sol";
import {MyToken} from "../src/W2/D4/MyToken.sol";

contract MyTokenScript is Script {
    MyToken public token;

    function deploy() public {
        vm.startBroadcast();

        token = new MyToken("JJToken", "JJT");
        console.log("MyToken address: ", address(token));
        console.log("MyToken name: ", token.name());
        console.log("MyToken symbol: ", token.symbol());
        console.log("MyToken total supply: ", token.totalSupply());

        vm.stopBroadcast();
    }
}
