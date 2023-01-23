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
*/

contract TrueCoinflip is VRFConsumerBaseV2, ConfirmedOwner, ReentrancyGuard {
    using SafeERC20 for IERC20;

    event RequestSent(uint256 requestId, uint32 numWords);
    event RequestFulfilled(uint256 requestId, uint256[] randomWords);

    struct RequestStatus {
        bool fulfilled; 
        bool exists;
        uint256[] randomWords;
    }

    bool public alpha;
    mapping(uint256 => RequestStatus) public s_requests; /* requestId --> requestStatus */
    VRFCoordinatorV2Interface COORDINATOR;

    // Your subscription ID. EDITED in constructor.
    uint64 s_subscriptionId;

    // past requests Id.
    uint256[] public requestIds;

    // The gas lane to use, which specifies the maximum gas price to bump to.
    // For a list of available gas lanes on each network,
    // see https://docs.chain.link/docs/vrf/v2/subscription/supported-networks/#configurations
    bytes32 keyHash = 0x79d3d8832d904592c0bf9818b621522c988bb8b0c05cdc3b15aea1b6e8db0c15;

    uint32 callbackGasLimit = 100000; // not sure what this does.
    uint16 requestConfirmations = 3;
    uint32 numWords = 1;


    constructor( ) VRFConsumerBaseV2(0x2Ca8E0C643bDe4C2E08ab1fA0da3401AdAD7734D) ConfirmedOwner(msg.sender) {
        COORDINATOR = VRFCoordinatorV2Interface(0x2Ca8E0C643bDe4C2E08ab1fA0da3401AdAD7734D);
        s_subscriptionId = 8872;
    }

    // Assumes the subscription is funded sufficiently.
    function requestRandomWords() public onlyOwner returns (uint256 requestId) {
        // Will revert if subscription is not set and funded.
        requestId = COORDINATOR.requestRandomWords(keyHash, s_subscriptionId, requestConfirmations, callbackGasLimit, numWords);
        s_requests[requestId] = RequestStatus({randomWords: new uint256[](0), exists: true, fulfilled: false});
        requestIds.push(requestId);
        emit RequestSent(requestId, numWords);
        return requestId;
    }
    
    // Callback function called by Chainlink VRF coordinator.
    function fulfillRandomWords( uint256 _requestId, uint256[] memory _randomWords) internal override {
        require(s_requests[_requestId].exists, "request not found");
        uint s_randomRange = (_randomWords[0] % 2) + 1;
        s_requests[_requestId].fulfilled = true;
        s_requests[_requestId].randomWords = s_randomRange;
        alpha = true;

        emit RequestFulfilled(_requestId, _randomWords);
    }

    function getRequestStatus(uint256 _requestId) external view returns (bool fulfilled, uint256[] memory randomWords) {
        require(s_requests[_requestId].exists, "request not found");
        RequestStatus memory request = s_requests[_requestId];
        return (request.fulfilled, request.randomWords);
    }
}


