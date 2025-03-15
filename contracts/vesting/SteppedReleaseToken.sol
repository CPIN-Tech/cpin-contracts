// SPDX-License-Identifier: MIT

pragma solidity ^0.8.3;

import "./openzeppelin-solidity-4.0/Math.sol";
import "./openzeppelin-solidity-4.0/Ownable.sol";
import "./openzeppelin-solidity-4.0/SafeERC20.sol";
import "./openzeppelin-solidity-4.0/ReentrancyGuard.sol";

import "./NonTransferrableToken.sol";
import "../interfaces/IReleaseToken.sol";

/**
 * Non-transferrable token with a linear release schedule.
 */
contract SteppedReleaseToken is NonTransferrableToken, Ownable, IReleaseToken, ReentrancyGuard {
    using SafeERC20 for IERC20;

    uint64 public startTime;

    uint64 public cliffEndTime;

    uint64 public endTime;

    uint64 public interval;

    /// @notice Token to release
    IERC20 public immutable token;

    /// @notice Unallocated share
    uint256 public unallocated;

    /// @notice The total number of tokens ever allocated to each address.
    mapping(address => uint256) public accountAllocations;

    /// @notice The total number of tokens each address ever claimed.
    mapping(address => uint256) public accountClaims;

    /**
     * @notice Creates a LinearReleaseToken. Transfer `amount_` tokens to this contract after it's deployed.
     *
     * @param name_ Name of the ERC20 token
     * @param symbol_ Symbol of the ERC20 token
     * @param decimals_ Decimals of the ERC20 token
     * @param owner_ who can send tokens to others
     * @param token_ the token that is released
     * @param amount_ amount of tokens to lock up
     * @param startTime_ when release starts
     * @param cliffEndTime_ when the cliff starts. If set to 0, this does not take effect.
     * @param endTime_ when release ends
     */
    constructor(
        string memory name_,
        string memory symbol_,
        uint8 decimals_,
        address owner_,
        address token_,
        uint256 amount_,
        uint64 startTime_,
        uint64 cliffEndTime_,
        uint64 endTime_,
        uint64 interval_
    ) NonTransferrableToken(name_, symbol_, decimals_) {
        transferOwnership(owner_);
        token = IERC20(token_);
        unallocated = amount_;
        startTime = startTime_;
        cliffEndTime = cliffEndTime_;
        endTime = endTime_;
        interval = interval_;
    }

    /**
     * Allocates release tokens to the specified holders.
     * @param _holders Array of holders of release tokens
     * @param _amounts Array of amounts of tokens to issue
     */
    function allocate(
        address[] calldata _holders,
        uint256[] calldata _amounts
    ) external override onlyOwner {
        require(_holders.length == _amounts.length, "LinearReleaseToken: length mismatch");
        require(_holders.length <= 20, "LinearReleaseToken: max 20 holders at initial allocation");
        for (uint8 i = 0; i < _holders.length; i++) {
            _allocate(_holders[i], _amounts[i]);
        }
    }

    function updateTiming(
        uint64 startTime_,
        uint64 cliffEndTime_,
        uint64 endTime_,
        uint64 interval_
    ) external onlyOwner {
        startTime = startTime_;
        cliffEndTime = cliffEndTime_;
        endTime = endTime_;
        interval = interval_;
    }

    function _allocate(address _holder, uint256 _amount) internal {
        unallocated -= _amount;
        accountAllocations[_holder] += _amount;
        _mintBalance(_holder, _amount);
        emit Allocated(_holder, _amount);
    }

    /**
     * Computes the number of tokens that the address can redeem.
     */
    function earned(address _owner) public view override returns (uint256) {
        // compute the total amount of tokens earned if this holder never claimed
        uint256 earnedIfNeverClaimed = releasableSupplyOfPrincipal(accountAllocations[_owner]);
        if (earnedIfNeverClaimed == 0) {
            return 0;
        }

        // subtract the total already claimed by the address
        return earnedIfNeverClaimed - accountClaims[_owner];
    }

    /**
     * The total amount of tokens that can be redeemed if all
     * tokens were distributed.
     */
    function releasableSupply() public view returns (uint256) {
        return releasableSupplyOfPrincipal(totalSupply() + unallocated);
    }

    /**
     * Computes the releasable supply of the given principal amount.
     */
    function releasableSupplyOfPrincipal(uint256 _principal) public view returns (uint256) {
        // solhint-disable-next-line not-rely-on-time
        uint256 start = uint256(startTime);
        uint256 end = uint256(endTime);
        if (block.timestamp < startTime || block.timestamp < uint256(cliffEndTime)) {
            return 0;
        }
        uint256 secondsSinceStart = Math.min(block.timestamp, end) - start; // solhint-disable-next-line not-rely-on-time
        uint256 adjustedDuration = (secondsSinceStart / uint256(interval)) * uint256(interval);
        return (_principal * adjustedDuration) / (end - start);
    }

    /**
     * Claims any tokens that the sender is entitled to.
     */
    function claim() public override nonReentrant {
        uint256 amount = earned(msg.sender);
        if (amount == 0) {
            // don't do anything if the sender has no tokens.
            return;
        }

        accountClaims[msg.sender] += amount;
        _burnBalance(msg.sender, amount);
        token.safeTransfer(msg.sender, amount);
        emit Claimed(msg.sender, amount);
    }
}
