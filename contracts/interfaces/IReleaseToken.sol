// SPDX-License-Identifier: MIT

pragma solidity ^0.8.3;

interface IReleaseToken {
    function earned(address _owner) external view returns (uint256);

    function allocate(address[] calldata _holders, uint256[] calldata _balances) external;

    function claim() external;

    /**
     * Called when tokens are allocated to someone.
     */
    event Allocated(address indexed owner, uint256 amount);

    /**
     * Called when tokens are claimed by someone.
     */
    event Claimed(address indexed owner, uint256 amount);
}
