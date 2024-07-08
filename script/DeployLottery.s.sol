// SPDX-License-Identifier: MIT

pragma solidity ^0.8.19;

import {Script} from "forge-std/Script.sol";
import {Lottery} from "../src/Lottery.sol";
import {HelperConfig} from "./HelperConfig.s.sol";
import {CreateSubscription, FundSubscription, AddConsumer} from "./Interactions.s.sol";


contract DeployLottery is Script {
    function run() external returns(Lottery, HelperConfig) {
        HelperConfig helperConfig = new HelperConfig();
        (uint256 entranceFee,
        uint256 interval,
        address vrfCoordinator,
        bytes32 gaslane,
        uint64 subscriptionID,
        uint32 callbackGasLimit,
        address link) = helperConfig.activeNetworkConfig();

        if (subscriptionID == 0) {
            CreateSubscription createSubscripion = new CreateSubscription();
            subscriptionID =  createSubscripion.createSubscription(vrfCoordinator);

            FundSubscription fundSubscription= new FundSubscription();
            fundSubscription.fundSubscription(vrfCoordinator, subscriptionID, link);
        }
        
        vm.startBroadcast();
        Lottery lottery = new Lottery(entranceFee, interval, vrfCoordinator, gaslane, subscriptionID, callbackGasLimit);
        vm.stopBroadcast();

        AddConsumer addConsumer = new AddConsumer();
        addConsumer.addConsumer(address(lottery), vrfCoordinator, subscriptionID);

        return (lottery, helperConfig);
    }
}