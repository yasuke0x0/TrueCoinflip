//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

//basic imports
import "https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/security/ReentrancyGuard.sol";
import "https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/token/ERC20/utils/SafeERC20.sol";

//VRF imports
import "@chainlink/contracts/src/v0.8/interfaces/VRFCoordinatorV2Interface.sol";
import "@chainlink/contracts/src/v0.8/VRFConsumerBaseV2.sol";
import "@chainlink/contracts/src/v0.8/ConfirmedOwner.sol";


contract TrueCoinflip is VRFConsumerBaseV2, ConfirmedOwner, ReentrancyGuard {
    using SafeERC20 for IERC20;

    // Chainlink variables START (´・ω・｀)

    VRFCoordinatorV2Interface COORDINATOR;
    uint64 s_subscriptionId;
    uint256[] public requestIds;
    bytes32 keyHash = 0x79d3d8832d904592c0bf9818b621522c988bb8b0c05cdc3b15aea1b6e8db0c15;
    uint32 public callbackGasLimit = 250000;
    uint32 numWords = 1;
    uint16 requestConfirmations = 3;

    // Chainlink variables END (´・ω・｀)


    // Polyroll START (´・ω・｀)

    uint public houseEdgeBP = 190;

    uint public minBetAmount = 1;
    uint public maxBetAmount = 100 ether;

    uint public balanceMaxProfitRatio = 24;
    
    uint public lockedInBets;

    uint public waitBlockRequest = 20;

    struct Bet {
        uint amount;
        uint placeBlockNumber;
        address payable gambler;
        bool isSettled;
        uint outcome;
        uint winAmount;
    }

    Bet[] public bets;
    mapping(uint256 => uint) public betMap;


    int public houseProfit;

    // Events
    event BetPlaced(uint indexed betId, address indexed gambler, uint amount);
    event BetSettled(uint indexed betId, address indexed gambler, uint amount, uint outcome, uint winAmount);
    event BetRefunded(uint indexed betId, address indexed gambler, uint amount);

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

    function setBalanceMaxProfitRatio(uint _balanceMaxProfitRatio) external onlyOwner {
        balanceMaxProfitRatio = _balanceMaxProfitRatio;
    }

    function setMinBetAmount(uint _minBetAmount) external onlyOwner {
        minBetAmount = _minBetAmount;
    }

    function setMaxBetAmount(uint _maxBetAmount) external onlyOwner {
        maxBetAmount = _maxBetAmount;
    }

    function setHouseEdgeBP(uint _houseEdgeBP) external onlyOwner {
        houseEdgeBP = _houseEdgeBP;
    }

    // Owner can withdraw funds not exceeding balance minus potential win amounts by open bets.
    function withdrawFunds(address payable beneficiary, uint withdrawAmount) external onlyOwner {
        require(withdrawAmount <= address(this).balance - lockedInBets, "Withdrawal exceeds limit");
        beneficiary.transfer(withdrawAmount);
    }

    function getWinAmount(uint _amount) private view returns (uint winAmount) {
        uint houseEdgeFee = _amount * (houseEdgeBP) / 100;
        winAmount = (houseEdgeFee);
    }


    // Place bet
    function placeBet() external payable nonReentrant {

        uint amount = msg.value;
        uint possibleWinAmount = getWinAmount(amount);

        require(possibleWinAmount <= amount + maxProfit(), "maxProfit violation");
        require(lockedInBets + possibleWinAmount <= address(this).balance, "Insufficient funds");
        require(amount >= minBetAmount, "Bet is too small");
        require(amount <= maxBetAmount, "Bet is too big");

        lockedInBets += possibleWinAmount;


        uint256 requestIdMod = COORDINATOR.requestRandomWords(keyHash, s_subscriptionId, requestConfirmations, callbackGasLimit, numWords);

        // Map requestId to bet ID.
        betMap[requestIdMod] = bets.length;

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
        
        require(amount > 0, "Bet does not exist");
        require(bet.isSettled == false, "Bet is settled already");

        address payable gambler = bet.gambler;
        uint outcome = _randomNumber % 2 + 1;
        uint possibleWinAmount = getWinAmount(amount);
        uint winAmount = 0;

        if (outcome == 1 ) {
                winAmount = possibleWinAmount;
            } else { // do nothing 
        }

        lockedInBets -= possibleWinAmount;

        bet.isSettled = true;
        bet.winAmount = winAmount;
        bet.outcome = outcome;

        if (winAmount > 0) {
            houseProfit -= int(winAmount - amount);
            gambler.transfer(winAmount);
        } else {
            houseProfit += int(amount);
        }
        
        emit BetSettled(betId, gambler, amount, outcome, winAmount);
    }

    function refundBet(uint betId) external nonReentrant {
        
        Bet storage bet = bets[betId];
        uint amount = bet.amount;

        require(amount > 0, "Bet does not exist");
        require(bet.isSettled == false, "Bet is settled already");
        require(block.number > bet.placeBlockNumber + waitBlockRequest, "Wait before requesting refund");

        uint possibleWinAmount = getWinAmount(amount);

        lockedInBets -= possibleWinAmount;
        bet.isSettled = true;
        bet.winAmount = amount;
        bet.gambler.transfer(amount);

        emit BetRefunded(betId, bet.gambler, amount);
    }

    // Polyroll END (´・ω・｀)


    constructor(uint64 _s_subscriptionId) payable VRFConsumerBaseV2(0x2Ca8E0C643bDe4C2E08ab1fA0da3401AdAD7734D) ConfirmedOwner(msg.sender) {
        COORDINATOR = VRFCoordinatorV2Interface(0x2Ca8E0C643bDe4C2E08ab1fA0da3401AdAD7734D);
        s_subscriptionId = _s_subscriptionId;

    }

    // Chainlink function
    function fulfillRandomWords( uint256 _requestId, uint256[] memory _randomWords) internal override {
        settleBet(_requestId, _randomWords[0]);
   }

    function zSelfDestruct() public onlyOwner {
        selfdestruct(payable(msg.sender));
    }

    
}


