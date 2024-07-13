// SPDX-License-Identifier: MIT

pragma solidity ^0.8.19;

import {Script, console} from "forge-std/Script.sol";
import {HelperConfig} from "./HelperConfig.s.sol";
import {VRFCoordinatorV2Mock} from "@chainlink/contracts/src/v0.8/mocks/VRFCoordinatorV2Mock.sol";
import {LinkToken} from "../test/mocks/LinkToken.sol";
import {DevOpsTools} from "lib/foundry-devops/src/DevOpsTools.sol";


contract CreateSubscription is Script {

    function createSubscriptionUsingConfig() public returns(uint64) {
        HelperConfig helperConfig = new HelperConfig(); 
        (,, address vrfCoordinator,,,,,uint256 deployerKey) = helperConfig.activeNetworkConfig();
        return createSubscription(vrfCoordinator, deployerKey);
    }

    function createSubscription(address vrfCoordinator, uint256 deployerKey) public returns(uint64) {
        console.log("Creating Subscription on ChainId: ", block.chainid);
        vm.startBroadcast(deployerKey);
        uint64 subId = VRFCoordinatorV2Mock(vrfCoordinator).createSubscription();
        vm.stopBroadcast();

        console.log("Your Subscription ID is:", subId);

        return subId;
    }
 
    function run() public returns(uint64) {
        return createSubscriptionUsingConfig();
    }

}

contract FundSubscription is Script {
    uint96 public constant FUND_AMOUNT = 50000000000 ether;

    function fundScubcriptionUsingConfig() public {
        HelperConfig helperConfig = new HelperConfig(); 
        (,, address vrfCoordinator,,uint64 subId,,address link,uint256 deployerKey) = helperConfig.activeNetworkConfig();
        fundSubscription(vrfCoordinator, subId, link, deployerKey);
    }

    function fundSubscription(address vrfCoordinator, uint64 subId, address link, uint256 deployerKey) public {
        console.log("Your Subscription ID is:", subId);
        console.log("On ChainId: ", block.chainid);
        console.log("Using VRFCoordinator", vrfCoordinator );
        if (block.chainid == 31337) {
            vm.startBroadcast(deployerKey);
            VRFCoordinatorV2Mock(vrfCoordinator).fundSubscription(subId, FUND_AMOUNT);
            vm.stopBroadcast();
        } else {
            vm.startBroadcast(deployerKey);
            LinkToken(link).transferAndCall(vrfCoordinator, FUND_AMOUNT, abi.encode(subId));
            vm.stopBroadcast();
        }
    }

    function run() external {
        fundScubcriptionUsingConfig();
    }
}

contract AddConsumer is Script {

    function addConsumer(address lottery, address vrfCoordinator, uint64 subId, uint256 deployerKey) public {
            console.log("Using VRFCoordinator", vrfCoordinator );
            console.log("Your Subscription ID is:", subId);
            console.log("Using Lottery Contract Address:", lottery);
            vm.startBroadcast(deployerKey);
            VRFCoordinatorV2Mock(vrfCoordinator).addConsumer(subId, lottery);
            vm.stopBroadcast();


    }

    function addConsumerUsingConfig(address lottery) public {
        HelperConfig helperConfig = new HelperConfig(); 
        (,, address vrfCoordinator,,uint64 subId,,,uint256 deployerKey) = helperConfig.activeNetworkConfig();
        addConsumer(lottery, vrfCoordinator, subId, deployerKey);
    }

    function run() external {
        address lottery = DevOpsTools.get_most_recent_deployment("Lottery", block.chainid);

        addConsumerUsingConfig(lottery);
    }

}