//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

// 0x1cb44424896e1473bac6629dfc6976956d516d16
// verified at https://goerli.etherscan.io/address/0x1cb44424896e1473bac6629dfc6976956d516d16

//basic imports
import "https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/security/ReentrancyGuard.sol";
import "https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/token/ERC20/utils/SafeERC20.sol";

//dummy import
import "./DummyERC20.sol";

//VRF imports
import "@chainlink/contracts/src/v0.8/interfaces/VRFCoordinatorV2Interface.sol";
import "@chainlink/contracts/src/v0.8/VRFConsumerBaseV2.sol";
import "@chainlink/contracts/src/v0.8/ConfirmedOwner.sol";


// Note: this contract uses the chainlink vrf subscription method


contract TrueCoinflip is VRFConsumerBaseV2, ConfirmedOwner, ReentrancyGuard {
    using SafeERC20 for IERC20;

    // Chainlink (´・ω・｀)
    VRFCoordinatorV2Interface COORDINATOR;
    bytes32 keyHash = 0x79d3d8832d904592c0bf9818b621522c988bb8b0c05cdc3b15aea1b6e8db0c15;
    uint32 s_subscriptionId;
    uint32 public callbackGasLimit = 100000 * 3;
    uint16 requestConfirmations = 3;
    uint8 numWords = 1;
    // Chainlink variables END (´・ω・｀)


    // Polyroll START (´・ω・｀)

    //public token variable
    ERC20 public dummyERC20;

    //hijacked this variable to turn it into 190% profit if win. This variable has been MODIFIED from source.
    uint public houseEdgeBP = 190;

    uint public minBetAmount = 1;
    uint public maxBetAmount = 100 ether;
    uint public balanceMaxProfitRatio = 24;
    uint public lockedInBets;

    address public token;

    uint16 public waitBlockRequest = 20;

        // Info of each bet.
    struct Bet {
        uint amount;
        uint placeBlockNumber;
        address payable gambler;
        bool isSettled; 
        uint outcome; // Outcome of bet. 0 = isSettled false, 1 = win, 2 = loss
        uint winAmount;
    }

    Bet[] public bets;
    mapping(uint256 => uint) public betMap;


    int public houseProfit;

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

    function balanceToken() public view returns (uint) {
        return IERC20(token).balanceOf(address(this));
    }


    function transferFrom(uint _amount) public {
    IERC20(token).transfer(address(this), _amount);
    }

    function setwaitBlockRequest(uint16 _waitBlockRequest) external onlyOwner {
        waitBlockRequest = _waitBlockRequest;
    }
    
    function setToken(address _token) external onlyOwner {
        token = _token;
    }

    function betsLength() external view returns (uint) {
        return bets.length;
    }

    // Returns maximum profit allowed per bet. Prevents contract from accepting any bets with potential profit exceeding maxProfit.
    function maxProfit() public view returns (uint) {
        return balanceToken() / balanceMaxProfitRatio;
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

    // Owner can withdraw non-MATIC tokens. Owner may rug here, need to add a token.balanceOf - lockedInBets check.
    function withdrawTokenAll(address _beneficiary) external onlyOwner {
        IERC20(token).safeTransfer(_beneficiary, IERC20(token).balanceOf(address(this)));
    }

    // Owner can withdraw non-MATIC tokens.
    function withdrawTokenSome(address _beneficiary, uint _amount) external onlyOwner {
        require(_amount <= balanceToken() - lockedInBets, "ERC20 Withdrawal exceeds limit");
        IERC20(token).safeTransfer(_beneficiary, _amount);
    }

    // Returns the expected win amount. This function has been modified from Polyroll.
    function getWinAmount(uint _amount) private view returns (uint winAmount) {
        uint houseEdgeFee = _amount * (houseEdgeBP) / 100;
        winAmount = (houseEdgeFee);
    }


    function placeBet(uint _amount) external nonReentrant {

        uint amount = _amount;
        uint possibleWinAmount = getWinAmount(amount);

        require(possibleWinAmount <= amount + maxProfit(), "maxProfit violation");
        require(lockedInBets + possibleWinAmount <= balanceToken(), "Insufficient funds");
        require(amount >= minBetAmount, "Bet is too small"); 
        require(amount <= maxBetAmount, "Bet is too big");

        IERC20(token).transfer(address(this), _amount);

        lockedInBets += possibleWinAmount;

        // Request random number from Chainlink VRF. Store requestId for validation checks later.
        uint256 requestIdMod = COORDINATOR.requestRandomWords(keyHash, s_subscriptionId, requestConfirmations, callbackGasLimit, numWords);

        betMap[requestIdMod] = bets.length;

        emit BetPlaced(bets.length, msg.sender, amount);

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
            } // else { do nothing }

        lockedInBets -= possibleWinAmount;

        bet.isSettled = true;
        bet.winAmount = winAmount;
        bet.outcome = outcome;

        if (winAmount > 0) {
            houseProfit -= int(winAmount - amount);
            IERC20(token).safeTransfer(bet.gambler, winAmount);
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
        IERC20(token).safeTransfer(bet.gambler, amount);

        emit BetRefunded(betId, bet.gambler, amount);
    }

    // Polyroll END (´・ω・｀)


    constructor(uint32 _s_subscriptionId) payable VRFConsumerBaseV2(0x2Ca8E0C643bDe4C2E08ab1fA0da3401AdAD7734D) ConfirmedOwner(msg.sender) {
        COORDINATOR = VRFCoordinatorV2Interface(0x2Ca8E0C643bDe4C2E08ab1fA0da3401AdAD7734D);
        s_subscriptionId = _s_subscriptionId;
        create();
    }

    // Dummy ERC20 （＾O＾）
    function create() public {
        dummyERC20 = new ERC20("DummyERC20", "XYZ");
        token = address(dummyERC20);
    }

    // create to mint additional tokens for further testing.
    function mintToken(uint _amount) external {
        dummyERC20._mint(msg.sender, _amount);
        }

    // created to mint additional token to contract for further testing.
    function mintTokenToContract(uint _amount) external {
        dummyERC20._mint(address(this), _amount);
        }

    // Chainlink callback function
    function fulfillRandomWords( uint256 _requestId, uint256[] memory _randomWords) internal override {
    settleBet(_requestId, _randomWords[0]);
    }
    
}




