// SPDX-License-Identifier: MIT

pragma solidity ^0.8.19;

import {Test, console} from "forge-std/Test.sol";
import {Lottery} from "../../src/Lottery.sol";
import {DeployLottery} from "../../script/DeployLottery.s.sol";
import {HelperConfig} from "../../script/HelperConfig.s.sol";
import {Vm} from "forge-std/Vm.sol";
import {VRFCoordinatorV2Mock} from "@chainlink/contracts/src/v0.8/mocks/VRFCoordinatorV2Mock.sol";

contract DeployLotteryTest is Test {
    function setUp() external {}

    function testDeployLotteryDeploysCorrectly() public {
        DeployLottery deployLottery = new DeployLottery();
        (Lottery lottery, HelperConfig helperConfig) = deployLottery.run();

        assert(uint160(address(lottery)) > 0);
        assert(uint160(address(helperConfig)) > 0);
    }
}