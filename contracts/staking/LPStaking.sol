// SPDX-License-Identifier: LGPL-3.0-or-later
pragma solidity ^0.7.0;

//import "https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/token/ERC20/IERC20.sol";
//import "https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/access/Ownable.sol";
//import "https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/math/SafeMath.sol";
import "@openzeppelin/contracts/math/SafeMath.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

// TODO: wait ./StakingOwner.sol

contract LPStaking is Ownable {
    using SafeMath for uint;

    uint constant doubleScale = 10 ** 36;

    // stake token
    IERC20 public stakeToken;

    // reward token
    IERC20 public rewardToken;

    // the number of reward token distribution for each block
    uint public rewardSpeed;

    // user deposit
    mapping(address => uint) public userCollateral;
    uint public totalCollateral;

    // use index to distribute reward token
    // index is compound exponential
    mapping(address => uint) public userIndex;
    uint public index;

    mapping(address => uint) public userAccrued;

    // record latest block height of reward token distributed
    uint public lastDistributedBlock;

    /* event */
    event Deposit(address user, uint amount);
    event Withdraw(address user, uint amount);
    event RewardSpeedUpdated(uint oldSpeed, uint newSpeed);
    event RewardDistributed(address indexed user, uint delta, uint index);

    constructor(address _stakeToken, address _rewardToken) Ownable(){
        stakeToken = _stakeToken;
        rewardToken = _rewardToken;
        index = doubleScale;
    }

    function deposit(uint amount) public {
        updateIndex();
        distributeReward(msg.sender);
        require(stakeToken.transferFrom(msg.sender, address(this), amount), "transferFrom failed");
        userCollateral[msg.sender] = userCollateral[msg.sender].add(amount);
        totalCollateral = totalCollateral.add(amount);
        emit Deposit(msg.sender, amount);
    }

    function withdraw(uint amount) public {
        updateIndex();
        distributeReward(msg.sender);
        require(stakeToken.transfer(msg.sender, amount), "transfer failed");
        userCollateral[msg.sender] = userCollateral[msg.sender].sub(amount);
        totalCollateral = totalCollateral.sub(amount);
        emit Withdraw(msg.sender, amount);
    }

    function setRewardSpeed(uint speed) public onlyOwner {
        updateIndex();
        uint oldSpeed = rewardSpeed;
        rewardSpeed = speed;
        emit RewardSpeedUpdated(oldSpeed, speed);
    }

    function updateIndex() private {
        uint blockDelta = block.number.sub(lastDistributedBlock);
        if (blockDelta == 0) {
            return;
        }
        uint rewardAccrued = blockDelta.mul(rewardSpeed);
        if (totalCollateral > 0) {
            uint indexDelta = rewardAccrued.mul(doubleScale).div(totalCollateral);
            index = index.add(indexDelta);
        }
        lastDistributedBlock = block.number;
    }

    function distributeReward(address user) private {
        if (userIndex[user] == 0 && index > 0) {
            userIndex[user] = doubleScale;
        }
        uint indexDelta = index - userIndex[user];
        userIndex[user] = index;
        uint rewardDelta = indexDelta.mul(userCollateral[user]).div(doubleScale);
        userAccrued[user] = userAccrued[user].add(rewardDelta);
        if (rewardToken.balanceOf(owner) >= userAccrued[user] && userAccrued[user] > 0) {
            if (rewardToken.transferFrom(owner, user, userAccrued[user])) {
                userAccrued[user] = 0;
            }
        }
        emit RewardDistributed(user, rewardDelta, index);
    }

    function claimReward(address[] memory user) public {
        updateIndex();
        for (uint i = 0; i < user.length; i++) {
            distributeReward(user[i]);
        }
    }

    function pendingReward(address user) public view returns (uint){
        uint blockDelta = block.number.sub(lastDistributedBlock);
        uint rewardAccrued = blockDelta.mul(rewardSpeed);
        if (totalCollateral == 0) {
            return userAccrued[user];
        }
        uint ratio = rewardAccrued.mul(doubleScale).div(totalCollateral);
        uint currentIndex = index.add(ratio);
        uint uIndex = userIndex[user] == 0 && index > 0 ? doubleScale : userIndex[user];
        uint indexDelta = currentIndex - uIndex;
        uint rewardDelta = indexDelta.mul(userCollateral[user]).div(doubleScale);
        return rewardDelta + userAccrued[user];
    }
}