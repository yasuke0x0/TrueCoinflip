//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

// 0x2fB3910Ce6e7f5CBf2869C3969a4430946429630
// https://goerli.etherscan.io/address/0x2fB3910Ce6e7f5CBf2869C3969a4430946429630

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
    uint32 public callbackGasLimit = 100000 * 2;
    uint16 requestConfirmations = 3;
    uint32 numWords = 1;
    // Chainlink variables END (´・ω・｀)


    // Polyroll START (´・ω・｀)
    // Each bet is deducted 100 basis points (1%) in favor of the house
    // uint public houseEdgeBP = 100;

    //hijacked this variable to turn it into 190% profit if win. This variable has been MODIFIED from source.
    uint public houseEdgeBP = 190;

    uint public minBetAmount = 1;
    uint public maxBetAmount = 100 ether;

    uint public balanceMaxProfitRatio = 24; // might remove, not needed with hardcoded Profit Ratio.
    
        // Funds that are locked in potentially winning bets. Prevents contract from committing to new bets that it cannot pay out.
    uint public lockedInBets;

    // blocknumber

    uint public waitBlockRequest = 20;

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
    event BetPlaced(uint indexed betId, address indexed gambler, uint amount);
    event BetSettled(uint indexed betId, address indexed gambler, uint amount, uint outcome, uint winAmount);
    event BetRefunded(uint indexed betId, address indexed gambler, uint amount);

    // used to top up the contract.
    fallback() external payable {}
    receive() external payable {}

    function balance() external view returns (uint) {
        return address(this).balance;
    }

    function setCallbackGasLimit (uint32 _callbackGasLimit) external onlyOwner {
        callbackGasLimit = _callbackGasLimit;
    }

    function balanceToken(address _token) external view returns (uint) {
        return IERC20(_token).balanceOf(address(this));
    }

    function setwaitBlockRequest(uint _waitBlockRequest) external onlyOwner {
        waitBlockRequest = _waitBlockRequest;
    }

    function betsLength() external view returns (uint) {
        return bets.length;
    }

    // Returns maximum profit allowed per bet. Prevents contract from accepting any bets with potential profit exceeding maxProfit.
    function maxProfit() public view returns (uint) {
        return address(this).balance / balanceMaxProfitRatio;
    }

    // Set balance-to-maxProfit ratio. 
    function setBalanceMaxProfitRatio(uint _balanceMaxProfitRatio) external onlyOwner {
        balanceMaxProfitRatio = _balanceMaxProfitRatio;
    }

    // Set minimum bet amount. minBetAmount should be large enough such that its house edge fee can cover the Chainlink oracle fee.
    function setMinBetAmount(uint _minBetAmount) external onlyOwner {
        minBetAmount = _minBetAmount;
    }

    // Set maximum bet amount. Setting this to zero effectively disables betting.
    function setMaxBetAmount(uint _maxBetAmount) external onlyOwner {
        maxBetAmount = _maxBetAmount;
    }

    // Set house edge.
    function setHouseEdgeBP(uint _houseEdgeBP) external onlyOwner {
        houseEdgeBP = _houseEdgeBP;
    }

    // Owner can withdraw funds not exceeding balance minus potential win amounts by open bets.
    function withdrawFunds(address payable beneficiary, uint withdrawAmount) external onlyOwner {
        require(withdrawAmount <= address(this).balance - lockedInBets, "Withdrawal exceeds limit");
        beneficiary.transfer(withdrawAmount);
    }

    // Owner can withdraw non-MATIC tokens.
    function withdrawToken(address _token) external onlyOwner {
        IERC20(_token).safeTransfer(owner(), IERC20(_token).balanceOf(address(this)));
    }

    // Returns the expected win amount. This function has been MODIFIED from source.
    function getWinAmount(uint _amount) private view returns (uint winAmount) {
        uint houseEdgeFee = _amount * (houseEdgeBP) / 100;
        winAmount = (houseEdgeFee);
    }

    //working with `placeBet`, `settleBet` and `refundBet` on ETH and not IERC token.
    // That will be step 2.

    // Place bet
    function placeBet() external payable nonReentrant {

        // Validate input data.
        uint amount = msg.value;

        // Winning amount.
        uint possibleWinAmount = getWinAmount(amount);

        // Enforce max profit limit. Bet will not be placed if condition is not met.
        require(possibleWinAmount <= amount + maxProfit(), "maxProfit violation");

        // Check whether contract has enough funds to accept this bet.
        require(lockedInBets + possibleWinAmount <= address(this).balance, "Insufficient funds");

        require(amount >= minBetAmount, "Bet is too small"); // Initial Polyroll contract allowed for exceeding minimum bet amount.
        require(amount <= maxBetAmount, "Bet is too big");

        // Update lock funds.
        lockedInBets += possibleWinAmount;

        // Request random number from Chainlink VRF. Store requestId for validation checks later.
        // Commenting the following line out, not sure how to resolve this conflict.
        uint256 requestIdMod = requestRandomWords();

        // Map requestId to bet ID.
        betMap[requestIdMod] = bets.length;

        // Record bet in event logs. Placed before pushing bet to array in order to get the correct bets.length.
        emit BetPlaced(bets.length, msg.sender, amount);

        // Store bet in bet list.
        bets.push(Bet(
            {
                amount: amount,
                placeBlockNumber: block.number,
                gambler: payable(msg.sender),
                isSettled: false,
                outcome: 0,
                winAmount: 0
            }
        ));
    }

    // Settle bet. Function can only be called by fulfillRandomness function, which in turn can only be called by Chainlink VRF.
    function settleBet(uint _requestIdMod, uint _randomNumber) internal nonReentrant {
        
        uint betId = betMap[_requestIdMod];
        Bet storage bet = bets[betId];
        uint amount = bet.amount;
        
        // Validation checks.
        require(amount > 0, "Bet does not exist");
        require(bet.isSettled == false, "Bet is settled already");

        // Fetch bet parameters into local variables (to save gas).
        address payable gambler = bet.gambler;

        // Do a roll by taking a modulo of random number.
        uint outcome = _randomNumber % 2 + 1;

        // Win amount if gambler wins this bet
        uint possibleWinAmount = getWinAmount(amount);

        // Actual win amount by gambler.
        uint winAmount = 0;

        if (outcome == 1 ) {
                winAmount = possibleWinAmount;
            } else { // do nothing 
        }

        // Unlock possibleWinAmount from lockedInBets, regardless of the outcome.
        lockedInBets -= possibleWinAmount;

        // Update bet records
        bet.isSettled = true;
        bet.winAmount = winAmount;
        bet.outcome = outcome; // 0, not set, 1 =

        // Send prize to winner, add ROLL reward to loser, and update house profit.
        if (winAmount > 0) {
            houseProfit -= int(winAmount - amount);
            gambler.transfer(winAmount);
        } else {
            houseProfit += int(amount);
        }
        
        // Record bet settlement in event log.
        emit BetSettled(betId, gambler, amount, outcome, winAmount);
    }

    function refundBet(uint betId) external nonReentrant {
        
        Bet storage bet = bets[betId];
        uint amount = bet.amount;

        // Validation checks
        require(amount > 0, "Bet does not exist");
        require(bet.isSettled == false, "Bet is settled already");
        require(block.number > bet.placeBlockNumber + waitBlockRequest, "Wait before requesting refund");

        uint possibleWinAmount = getWinAmount(amount);

        // Unlock possibleWinAmount from lockedInBets, regardless of the outcome.
        lockedInBets -= possibleWinAmount;

        // Update bet records
        bet.isSettled = true;
        bet.winAmount = amount;

        // Send the refund.
        bet.gambler.transfer(amount);

        // Record refund in event logs
        emit BetRefunded(betId, bet.gambler, amount);
    }

    // Polyroll END (´・ω・｀)


    constructor( ) payable VRFConsumerBaseV2(0x2Ca8E0C643bDe4C2E08ab1fA0da3401AdAD7734D) ConfirmedOwner(msg.sender) {
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
    s_requests[_requestId].randomWords = _randomWords;
    s_requests[_requestId].fulfilled = true; // delete this if not necessary.
    s_requests[_requestId].randomness = (_randomWords[0] % 2) + 1; // return 0 on not set, 1 win, 2 lose. delete this if not necessary.
https://github.com/YasuBlockchain/TrueCoinflip/blob/main/0_back/2_Goerli/1_TrueCoinflipETH.sol    }

    function getRequestStatus(uint256 _requestId) external view returns (bool fulfilled, uint randomness, uint256[] memory randomWords) {
    require(s_requests[_requestId].exists, "request not found");
    RequestStatus memory request = s_requests[_requestId];
    return (request.fulfilled, request.randomness, request.randomWords);
    }   
    // Chainlink function END

    function zSelfDestruct() public onlyOwner {
        selfdestruct(payable(msg.sender));
    }

    
}


