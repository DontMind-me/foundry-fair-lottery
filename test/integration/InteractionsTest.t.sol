// SPDX-License-Identifier: MIT

pragma solidity ^0.8.19;

import {Test, console} from "forge-std/Test.sol";
import {CreateSubscription, FundSubscription, AddConsumer} from "../../script/Interactions.s.sol";
import {DeployLottery} from "../../script/DeployLottery.s.sol";
import {HelperConfig} from "../../script/HelperConfig.s.sol";
import {Vm} from "forge-std/Vm.sol";
import {VRFCoordinatorV2Mock} from "@chainlink/contracts/src/v0.8/mocks/VRFCoordinatorV2Mock.sol";
import {Lottery} from "../../src/Lottery.sol";

contract InteractionsTest is Test {

    address vrfCoordinator;
    uint64 subscriptionID;
    address link;
    uint256 deployerKey;

    CreateSubscription createSubscription;
    FundSubscription fundSubscription;
    AddConsumer addConsumer;
    Lottery lottery;
    HelperConfig helperConfig;


    function setUp() external {
        DeployLottery deployLottery = new DeployLottery();
        (lottery, helperConfig) = deployLottery.run();
        (, , vrfCoordinator, , subscriptionID, , link, deployerKey) = helperConfig.activeNetworkConfig();
        vm.startBroadcast();
        createSubscription = new CreateSubscription();
        fundSubscription = new FundSubscription();
        addConsumer = new AddConsumer();
        vm.stopBroadcast();
    }

    function testCreatesubscriptionCreatesSubscription() public {
        uint64 subId = createSubscription.run();
        assert(subId > 0);
    }



    
}
