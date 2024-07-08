
//SPDX-License_identifier: MIT

pragma solidity ^0.8.19;

 import {VRFCoordinatorV2Interface} from "@chainlink/contracts/src/v0.8/vrf/interfaces/VRFCoordinatorV2Interface.sol";
 import {VRFConsumerBaseV2} from "@chainlink/contracts/src/v0.8/vrf/VRFConsumerBaseV2.sol";

/**
 *@title Fair Lottery Contract
 *@author Ifra Muazzam
 *@notice Contract is for creating a sample Lottery
 *@dev Implements Chainlink VRFv2
 */

 //CEI: Checks, Effects, Interactions

contract Lottery is VRFConsumerBaseV2 {
    error Lottery__NotEnoughEthSent();
    error Lottery__TransferFail();
    error Lottery__LotteryNotOpen();
    error Lottery__UpkeepNotNeeded(
        uint256 curentBalance,
        uint256 numPlayers,
        uint256 lotteryState
    );

    /** Type Declaration */
    enum LotteryState {
        OPEN,
        CALCULATING
    }

    /** State Variables */
    uint16 private constant REQUEST_CONFIRMATIONS = 3;
    uint32 private constant NUM_WORDS = 1;

    uint256 private immutable i_entranceFee;
    uint256 private immutable i_interval;
    VRFCoordinatorV2Interface private immutable i_vrfCoordinator;
    bytes32 private immutable i_gaslane;
    uint64 private immutable i_subscriptionID;
    uint32 private immutable i_callbackGasLimit;

    uint256 private s_lastTimeStamp;
    address payable[] private s_players;
    address private s_recentWinner;
    LotteryState private s_lotteryState;
    

    /** Events */

    event EnteredLottery(address indexed player);
    event WinnerPicked(address indexed winner);
    event WinnerRequested(uint256 indexed request_Id);

    constructor(uint256 entranceFee, uint256 interval, address vrfCoordinator, bytes32 gaslane, uint64 subscriptionID, uint32 callbackGasLimit) VRFConsumerBaseV2(vrfCoordinator) {
        i_entranceFee = entranceFee;
        i_interval = interval;
        s_lastTimeStamp = block.timestamp;
        i_vrfCoordinator = VRFCoordinatorV2Interface(vrfCoordinator);
        i_gaslane = gaslane;
        i_subscriptionID = subscriptionID;
        i_callbackGasLimit = callbackGasLimit;
        s_lotteryState = LotteryState.OPEN;
        
    } 

    function enterLottery() external payable {

        if (s_lotteryState != LotteryState.OPEN) {
            revert Lottery__LotteryNotOpen();
        }

        if(msg.value < i_entranceFee) {
            revert Lottery__NotEnoughEthSent();
        }

        s_players.push(payable(msg.sender));

        emit EnteredLottery(msg.sender);
    }

    /**
    *@dev This is a function which the Chainlink Automation nodes call to see if its time to perform an upkeep. 
    * The following conditions must be true for this to return true:
    * 1. The time interval has passed 
    * 2. Lottery is in OPEN STATE
    * 3. Contract has ETH (also meaning it needs players)
     */

     function checkUpkeep(bytes memory /* checkData */) public view returns (bool upkeepNeeded, bytes memory /* performData */) {
        bool timeHasPassed = (block.timestamp - s_lastTimeStamp >= i_interval);
        bool isOpen = LotteryState.OPEN == s_lotteryState;
        bool hasETH = address(this).balance > 0;
        bool hasPlayers = s_players.length > 0;
        upkeepNeeded = (timeHasPassed && isOpen && hasETH && hasPlayers);
        return (upkeepNeeded, "0x0");
     }
    
    function performUpkeep(bytes calldata /* performData */) external {
        (bool upkeepNeeded,) = checkUpkeep("");
        if (!upkeepNeeded) {
            revert Lottery__UpkeepNotNeeded(
                address(this).balance,
                s_players.length,
                uint256(s_lotteryState)
            );
        }

        s_lotteryState = LotteryState.CALCULATING;

        uint256 requestId = i_vrfCoordinator.requestRandomWords(
            i_gaslane,
            i_subscriptionID,
            REQUEST_CONFIRMATIONS,
            i_callbackGasLimit,
            NUM_WORDS
        );
        emit WinnerRequested(requestId);
    }

    function fulfillRandomWords(uint256 requestId, uint256[] memory randomWords) internal override {
        uint256 indexOfWinner = randomWords[0] % s_players.length;
        address payable winner = s_players[indexOfWinner];
        s_recentWinner = winner;
        s_lotteryState = LotteryState.OPEN;

        s_players = new address payable[](0);
        s_lastTimeStamp = block.timestamp;
 
        emit WinnerPicked(winner);

        (bool success,) = winner.call{value:address(this).balance}("");
        if (!success) {
            revert  Lottery__TransferFail();
        }

    }


    /** Getter Functions */

    function getEntranceFee() external view returns(uint256) {
        return i_entranceFee;
    }

    function getLotteryState() external view returns(LotteryState) {
        return s_lotteryState;
    }

    function getPlayers(uint256 index) external view returns(address) {
        return s_players[index];
    }

    function getRecentWinner() external view returns(address) {
        return s_recentWinner;
    }
    function getPlayerLength() external view returns(uint256) {
        return s_players.length;
    }

    function getLastTimeStamp() external view returns(uint256) {
        return s_lastTimeStamp;
    }
 
}
