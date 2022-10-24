// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

// Uncomment this line to use console.log
// import "hardhat/console.sol";

import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/security/PausableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/utils/SafeERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC721/ERC721Upgradeable.sol";


contract Tokenization is
    Initializable, 
    PausableUpgradeable,
    ReentrancyGuardUpgradeable
{
    using SafeERC20Upgradeable for IERC20Upgradeable;

    /// game publisher and reward token owner
    address public publisher;
    /// Elixir platform 
    address public owner;
    /// game identification
    uint256 public gameId;

    // Reward tokens
    /// ERC20 reward token address
    address public rewardTokenERC20;    
    /// ERC721 reward token address
    address public rewardTokenERC721;   

    // Limits
    /// date until which the program will be active
    uint48 public programEndTime;       
    /// amount of rewards delivered so far
    uint256 public totalRewardAmount;   
    /// maximum amount of reward that the program will deliver
    uint256 public maxRewardAmount;     
    /// Minimum amount for the user to claim rewards.
    uint256 public minClaimAmount;      

    // Referee reward info
    /// ERC721 reward amount for the referee user
    uint16 public refereeRewAmountERC721;   
    /// ERC20 reward amount for the referee user
    uint256 public refereeRewAmountERC20;   

    // EVENTS
    event tierSchemeUpdated(uint _tiersLength);
    event nftRewardIdsUpdated (uint _idsLength);
    event referralAdded(address _referral, address _referee);
    event rewardsClaimed(address _user);
    event programEndTimeUpdated (uint _newEndTime);
    event minClaimAmountUpdated (uint _newMinClaim);

    // MODIFIERS
    // check that the caller is the owner of the contract
    modifier onlyOwner() {
        require(msg.sender == owner, "Not owner");
        _;
    }
    // check that the caller is the publiser
    modifier onlyPublisher() {
        require(msg.sender == publisher, "Not publisher");
        _;
    }
    // check that the caller is the owner or publiser
    modifier onlyAdmins() {
        require(msg.sender == publisher || msg.sender == owner, "Not an admin");
        _;
    }
     /**
     * @notice Clone initializer function
     * @param _owner Publisher address (reward token owner)
     * @param _publisher Publisher address (reward token owner)
     * @param _gameId game identification
     * @param _rewardTokenERC20 ERC20 reward token address
     * @param _rewardTokenERC721 ERC721 reward token address
     * @param _programEndTime Date until which the program will be active
     * @param _maxRewardAmount Maximum amount of reward that the program will deliver
     * @param _minClaimAmount Minimum amount for the user to claim rewards
     * @param _refereeRewAmountERC20 ERC20 reward amount for the referee user
     * @param _refereeRewAmountERC721 ERC721 reward amount for the referee user
     */
    function initialize(
        address _owner,
        address _publisher,
        uint256 _gameId,
        address _rewardTokenERC20,
        address _rewardTokenERC721,
        uint256 _programEndTime,
        uint256 _maxRewardAmount,
        uint256 _minClaimAmount,
        uint256 _refereeRewAmountERC20,
        uint256 _refereeRewAmountERC721
    ) public initializer {
        require(_owner != address(0), "Zero address");
        owner = _owner;
        require(_publisher != address(0), "Zero address");
        publisher = _publisher;
        gameId = _gameId;
        // addresses check
        require(_rewardTokenERC20 != address(0), "Zero token address");
        require(_rewardTokenERC721 != address(0), "Zero token address");
        rewardTokenERC20 = _rewardTokenERC20;
        rewardTokenERC721 = _rewardTokenERC721;
        // limits
        require(uint48(_programEndTime) > block.timestamp, "Program end must be in future");
        programEndTime = uint48(_programEndTime);
        maxRewardAmount = _maxRewardAmount;
        minClaimAmount = _minClaimAmount;
        // referee rewards
        refereeRewAmountERC20 = _refereeRewAmountERC20;
        refereeRewAmountERC721 = uint16(_refereeRewAmountERC721);
    }

    // *** Administrative Actions ***


    /**
     * @notice Updates the ERC20 reward token
     * @param _newRewardToken new reward token address
     */
    function updateRewardTokenERC20(address _newRewardToken)
        onlyPublisher external
    {
        require(_newRewardToken != address(0), "Zero token address");
        rewardTokenERC20 = _newRewardToken;
    }

    /**
     * @notice Updates the date until which the program will be active
     * @param _newEndTime the new end date
     */
    function updateProgramEndTime(uint256 _newEndTime) onlyPublisher external  {
        require(_newEndTime > block.timestamp, "Program end must be in future");
        programEndTime = uint48(_newEndTime);
        emit programEndTimeUpdated(_newEndTime);
    }

    /**
     * @notice Updates max amount of reward that the program will deliver
     * @param _newMaxReward the new max reward amount
     */
    function updateMaxRewardAmount(uint256 _newMaxReward) onlyPublisher external  {
        maxRewardAmount = _newMaxReward;
    }

    /**
     * @notice Updates the minimum amount for the user to claim rewards.
     * @param _newMinClaim the new min reward amount to claim
     */
    function updateMinClaimAmount(uint256 _newMinClaim) onlyPublisher external  {
        minClaimAmount = _newMinClaim;
        emit minClaimAmountUpdated(_newMinClaim);
    }

    // *** NFTs rewards functions ***

    /**
     * @notice Updates the ERC721 reward token
     * @param _newRewardToken new reward token address
     */
    function updateRewardTokenERC721(address _newRewardToken)
       onlyPublisher external
    {
        require(_newRewardToken != address(0), "Zero token address");
        rewardTokenERC721 = _newRewardToken;
    }


    /**
     * @dev Triggers stopped state.
     * Requirements:
     * - The contract must not be paused.
     */
    function pause() external onlyAdmins  {
        _pause();
    }

    /**
     * @dev Returns to normal state.
     * Requirements:
     * - The contract must be paused.
     */
    function unpause() external onlyAdmins {
        _unpause();
    }

}
