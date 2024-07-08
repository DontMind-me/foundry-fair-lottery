// SPDX-License-Identifier: MIT

pragma solidity ^0.8.19;

import {Test, console} from "forge-std/Test.sol";
import {Lottery} from "../../src/Lottery.sol";
import {DeployLottery} from "../../script/DeployLottery.s.sol";
import {HelperConfig} from "../../script/HelperConfig.s.sol";
import {Vm} from "forge-std/Vm.sol";
import {VRFCoordinatorV2Mock} from "@chainlink/contracts/src/v0.8/mocks/VRFCoordinatorV2Mock.sol";

contract LotteryTest is Test {
    event EnteredLottery(address indexed player);
    event WinnerPicked(address indexed winner);

    Lottery lottery;
    HelperConfig helperConfig;
    
    uint256 entranceFee;
    uint256 interval;
    address vrfCoordinator;
    bytes32 gaslane;
    uint64 subscriptionID;
    uint32 callbackGasLimit;
    address link;

    address public PLAYER = makeAddr("PLAYER");
    uint256 public STARTING_BALANCE = 10 ether;
    uint256 public ENTERANCE_FEE = 1 ether;

    function setUp() external {
        DeployLottery deployLottery = new DeployLottery();
        (lottery, helperConfig) = deployLottery.run();
        (entranceFee, interval, vrfCoordinator, gaslane, subscriptionID, callbackGasLimit, link) = helperConfig.activeNetworkConfig();
        vm.deal(PLAYER, STARTING_BALANCE);
    }

    function testLotteryInitializesInOpenState() public {
        assert(lottery.getLotteryState() == Lottery.LotteryState.OPEN);
    }

    /////////////////////////////
    //////// ENTER RAFFLE ///////
    /////////////////////////////

    function testLoteryRevertsIfNotEnoughEth() public {
        vm.prank(PLAYER);
        vm.expectRevert(Lottery.Lottery__NotEnoughEthSent.selector);
        lottery.enterLottery();
    }

    function testCantEnterWhenRaffleIsCalculating() public {
        vm.prank(PLAYER);
        lottery.enterLottery{value: ENTERANCE_FEE}();
        vm.warp(block.timestamp + interval + 1);
        vm.roll(block.number + 1);
        lottery.performUpkeep("");

        vm.expectRevert(Lottery.Lottery__LotteryNotOpen.selector);
        vm.prank(PLAYER);
        lottery.enterLottery{value: ENTERANCE_FEE}();

    }

    function testLotteryUpdatesWhenSomeoneEnters() public {
        vm.prank(PLAYER);
        lottery.enterLottery{value: ENTERANCE_FEE}();
        assert(lottery.getPlayers(0) == PLAYER);
    }

    function testEventEmitsOnEntrance() public {
        vm.prank(PLAYER);
        vm.expectEmit(true,false,false,false,address(lottery));
        emit EnteredLottery(PLAYER);
        lottery.enterLottery{value: ENTERANCE_FEE}();

    }

    /////////////////////////////////
    ////////// CHECKUPKEP //////////
    ////////////////////////////////

    function testUpkeepIsFalseIFNOtEnoughTimeHasPassed() public {
        //Arrange
        vm.prank(PLAYER);
        lottery.enterLottery{value: 0.02 ether}();
        vm.roll(block.number + 1);
        //Act
        (bool upkeepNeeded,) = lottery.checkUpkeep("");
        //Assert
        assert(upkeepNeeded == false);
    }

    function testCheckUpKeepReturnsFalseIfNoBalance() public {
        //Arrange
        vm.warp(block.timestamp + interval + 1);
        vm.roll(block.number + 1);
        //Act
        (bool upkeepNeeded,) = lottery.checkUpkeep("");
        //Assert
        assert(upkeepNeeded == false);
    }

    function testcheckupKeepReturnsFalseIfLotteryCalculating() public {
        //Arrange
        vm.prank(PLAYER);
        lottery.enterLottery{value: ENTERANCE_FEE}();
        vm.warp(block.timestamp + interval + 1);
        vm.roll(block.number + 1);
        lottery.performUpkeep("");
        //Act
        (bool upkeepNeeded,) = lottery.checkUpkeep("");
        //Assert
        assert(upkeepNeeded == false);        

    }

    function testCheckupKeepReturnsTrueWhenAllParamaterAreCorrect() public {
        //Arrange
        vm.prank(PLAYER);
        lottery.enterLottery{value: ENTERANCE_FEE}();
        vm.warp(block.timestamp + interval + 1);
        vm.roll(block.number + 1);
        //Act
        (bool upkeepNeeded,) = lottery.checkUpkeep("");
        //Assert
        assert(upkeepNeeded == true);
    }

    //////////////////////////////////////
    ///////// PERFORMUPKEEP //////////////
    //////////////////////////////////////

    function testPerformupKeepOnlyRunsIfCheckupkeepIsTrue() public {
        //Arrange
        vm.prank(PLAYER);
        lottery.enterLottery{value: ENTERANCE_FEE}();
        vm.warp(block.timestamp + interval + 1);
        vm.roll(block.number + 1);

        //Act/Assert
        lottery.performUpkeep("");
    }

    function testPerformUpkeepRevertsIfCheckUpkeepIsFalse() public {
        //Arrange
        uint256 Balance = 0;
        uint256 numPlayers = 0;
        uint256 LotteryState = 0;
        //Act/Assert
        vm.expectRevert(abi.encodeWithSelector(Lottery.Lottery__UpkeepNotNeeded.selector, Balance, numPlayers, LotteryState));
        lottery.performUpkeep("");
    }

    modifier RaffleEnteredAndTimePassed() {
        vm.prank(PLAYER);
        lottery.enterLottery{value: ENTERANCE_FEE}();
        vm.warp(block.timestamp + interval + 1);
        vm.roll(block.number + 1);
        _;
    }

    function testPerformUpkeepUpdatesLotteryStateAndEmitsEvent() public RaffleEnteredAndTimePassed {
        //Arrange
        //Act
        vm.recordLogs();
        lottery.performUpkeep("");
        Vm.Log[] memory entries = vm.getRecordedLogs();
        bytes32 requestId = entries[1].topics[1];
        Lottery.LotteryState rState = lottery.getLotteryState();
        //Assert
        assert(uint256(requestId) > 0);
        assert(uint256(rState) == 1);
    }

    ////////////////////////////////////
    //////// FULFILLRANDOMWORDS ////////
    ////////////////////////////////////

    function testFulfillRandomWordsCanOnlyBeCalledAfterPerformUpkeep(uint256 randomRequestId) public RaffleEnteredAndTimePassed() {
        //Arrange
        vm.expectRevert("nonexistent request");
        VRFCoordinatorV2Mock(vrfCoordinator).fulfillRandomWords(randomRequestId, address(lottery));
    }

    function testFulfillRandomWordsPicksWinnerResetsAndSendsMoney() public RaffleEnteredAndTimePassed() {
        //Arrange
        uint256 startingIndex = 1;
        uint256 Entrants = 5;
        uint256 recentTimeStamp = lottery.getLastTimeStamp();

        for(uint256 i = startingIndex; i < startingIndex + Entrants; i++) {
            address player = address(uint160(i));
            hoax(player, STARTING_BALANCE);
            lottery.enterLottery{value: ENTERANCE_FEE}();
        }

        uint256 prize = ENTERANCE_FEE * (Entrants + 1);

        vm.recordLogs();
        lottery.performUpkeep("");
        Vm.Log[] memory entries = vm.getRecordedLogs();
        bytes32 requestId = entries[1].topics[1];

        //Act
        VRFCoordinatorV2Mock(vrfCoordinator).fulfillRandomWords(uint256(requestId), address(lottery));
        vm.expectEmit(true,false,false,false,address(lottery));
        emit WinnerPicked(lottery.getRecentWinner());
        //Assert
        // assert(uint256(lottery.getLotteryState()) == 0);
        // assert(lottery.getRecentWinner() != address(0));
        // assert(lottery.getPlayerLength() == 0);
        // assert(recentTimeStamp < lottery.getLastTimeStamp());
        console.log(lottery.getRecentWinner().balance);
        console.log(STARTING_BALANCE + prize - ENTERANCE_FEE);
        assert(lottery.getRecentWinner().balance == STARTING_BALANCE + prize - ENTERANCE_FEE);

    }



}