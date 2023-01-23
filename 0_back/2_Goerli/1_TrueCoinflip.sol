//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;


//basic imports
//import "https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/access/Ownable.sol";
import "https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/security/ReentrancyGuard.sol";
import "https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/token/ERC20/utils/SafeERC20.sol";

//VRF imports
import "@chainlink/contracts/src/v0.8/interfaces/VRFCoordinatorV2Interface.sol";
import "@chainlink/contracts/src/v0.8/VRFConsumerBaseV2.sol";
import "@chainlink/contracts/src/v0.8/ConfirmedOwner.sol";

// Wildwestcowboys.
/*
TODO

### Process:
    *. 1. player calls the `playConflip()` and gets to play the game.
        *. Checks:
    *. 2. player / bot / fallback calls `checkResults()` and contract receives answer if player won, lost or invalid. If %2 == 0, lost. If %2 == 1, win.

### Functions:
    *. Owner call fill up the CA.
    *. Owner can empty the CA.

### Testing:
    *. Create standard ERC20 token to test the contract with.
    *. Create RFI ERC20 token to test the contract with.
    *. Test on mainnet.

### Safety:
    *. Reentrancy
    *. Ownable. Could not import the above ownable for some strange reason. Conflict with another import ?
    *. Provably Fair Random Function

### Enhancement:
    *. Gas cost optimization
    *. Better code structure

### Note:
    This contract uses the subscription method, but may be able to use the direct funding method if it is better.


    Task 1, get 1 simple modulo function from this and have it ready. DONE.
    Task x, approve before interacting with the contract.
    Task x, play the game()

*/

contract TrueCoinflip is VRFConsumerBaseV2, ConfirmedOwner, ReentrancyGuard {
    using SafeERC20 for IERC20;

    // Chainlink variables START (´・ω・｀)
    event RequestSent(uint256 requestId, uint32 numWords);
    event RequestFulfilled(uint256 requestId, uint256[] randomWords);

    struct RequestStatus {
        bool fulfilled; 
        bool exists;
        uint randomness;
        uint256[] randomWords;
    }
    
    mapping(uint256 => RequestStatus) public s_requests; 
    VRFCoordinatorV2Interface COORDINATOR;
    uint64 s_subscriptionId;
    uint256[] public requestIds;
    bytes32 keyHash = 0x79d3d8832d904592c0bf9818b621522c988bb8b0c05cdc3b15aea1b6e8db0c15;
    uint32 callbackGasLimit = 100000;
    uint16 requestConfirmations = 3;
    uint32 numWords = 1;
    // Chainlink variables END (´・ω・｀)


    // Polyroll START (´・ω・｀)
    // Each bet is deducted 100 basis points (1%) in favor of the house
    uint public houseEdgeBP = 100;

    uint public minBetAmount = 1 ether;
    uint public maxBetAmount = 100 ether;
    
        // Funds that are locked in potentially winning bets. Prevents contract from committing to new bets that it cannot pay out.
    uint public lockedInBets;

        // Info of each bet.
    struct Bet {
        // Wager amount in wei.
        uint amount;
        // Block number of placeBet tx.
        uint placeBlockNumber;
        // Address of a gambler, used to pay out winning bets.
        address payable gambler;
        // Status of bet settlement.
        bool isSettled;
        // Outcome of bet.
        uint outcome;
        // Win amount.
        uint winAmount;
    }

    // Array of bets
    Bet[] public bets;
    // mapping(uint256 => Bet) public betMap; // Might use this but the below line was used in source, will check.


    // Mapping requestId returned by Chainlink VRF to bet Id.
    mapping(uint256 => uint) public betMap;


    // Signed integer used for tracking house profit since inception.
    int public houseProfit;

    // Events
    event BetPlaced(uint indexed betId, address indexed gambler, uint amount, uint8 indexed modulo, uint8 rollUnder, uint40 mask);
    event BetSettled(uint indexed betId, address indexed gambler, uint amount, uint8 indexed modulo, uint8 rollUnder, uint40 mask, uint outcome, uint winAmount, uint rollReward);
    event BetRefunded(uint indexed betId, address indexed gambler, uint amount);

    // used to top up the contract.
    fallback() external payable {}
    receive() external payable {}

    function balance() external view returns (uint) {
        return address(this).balance;
    }

    function balanceToken(address _token) external view returns (uint) {
        return IERC20(_token).balanceOf(address(this));
    }

    function betsLength() external view returns (uint) {
        return bets.length;
    }


    // Polyroll END (´・ω・｀)



    constructor( ) VRFConsumerBaseV2(0x2Ca8E0C643bDe4C2E08ab1fA0da3401AdAD7734D) ConfirmedOwner(msg.sender) {
        COORDINATOR = VRFCoordinatorV2Interface(0x2Ca8E0C643bDe4C2E08ab1fA0da3401AdAD7734D);
        s_subscriptionId = 8872;
    }

    // Chainlink function START
    function requestRandomWords() public onlyOwner returns (uint256 requestId) {
        // Will revert if subscription is not set and funded.
        requestId = COORDINATOR.requestRandomWords(keyHash, s_subscriptionId, requestConfirmations, callbackGasLimit, numWords);
        s_requests[requestId] = RequestStatus({randomness: 0, randomWords: new uint256[](0), exists: true, fulfilled: false});
        requestIds.push(requestId);
        emit RequestSent(requestId, numWords);
        return requestId;
    }
    
    function fulfillRandomWords( uint256 _requestId, uint256[] memory _randomWords) internal override {
    require(s_requests[_requestId].exists, "request not found");
    s_requests[_requestId].fulfilled = true;
    s_requests[_requestId].randomness = (_randomWords[0] % 2) + 1; // return 0 on not set, 1 on even and 2 uneven.
    }
    // Chainlink function END


    
}


