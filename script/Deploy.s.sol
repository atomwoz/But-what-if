// SPDX-License-Identifier: MIT
pragma solidity ^0.8.30;

import {Script, console} from "forge-std/Script.sol";
import {ButWhatIf} from "../src/ButWhatIf.sol";

contract DeployButWhatIf is Script {
    function run() external returns (ButWhatIf) {
        vm.startBroadcast();
        ButWhatIf butWhatIf = new ButWhatIf();
        vm.stopBroadcast();

        console.log("ButWhatIf deployed at:", address(butWhatIf));
        return butWhatIf;
    }
}
