// SPDX-License-Identifier: LGPL-3.0-or-later
pragma solidity ^0.7.0;

import "@openzeppelin/contracts/math/SafeMath.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "./LPStaking.sol";

// TODO

contract StakingOwner is Ownable {
    using SafeMath for uint;

    uint public constant scale = 10 ** 18;

    struct PoolInfo {
        uint weight;
        LPStaking pools;
    }

    uint public totalSpeed;
    uint public totalWeight;

    PoolInfo[] public pools;

    constructor()Ownable{}

    function poolNum() public view returns (uint){
        return pools.length;
    }

    function createPool(){}

    // update owner for each pool
    // transfer all rewardToken to new owner
    /// @notice the new owner should be msg.sender
    function migrate() public onlyOwner {

    }

    // change whole reward speed
    function updateSpeed(uint newSpeed) public onlyOwner {

    }

    function refreshSpeeds() internal {

    }
}
