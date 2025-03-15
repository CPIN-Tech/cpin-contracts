// SPDX-License-Identifier: MIT

pragma solidity ^0.8.3;

import "./vesting/SteppedReleaseToken.sol";

/**
 * Released CPIN token.
 */
contract ReleaseCpin is SteppedReleaseToken {
    constructor(
        address owner_,
        address cpin_token_,
        uint256 amount_,
        uint64 startTime_,
        uint64 cliffEndTime_,
        uint64 endTime_,
        uint64 interval_
    )
        SteppedReleaseToken(
            "Release CPIN",
            "rCPIN",
            18,
            owner_,
            cpin_token_,
            amount_,
            startTime_,
            cliffEndTime_,
            endTime_,
            interval_
        )
    // solhint-disable-next-line no-empty-blocks
    {
        // Do nothing
    }

    /**
     * @param _token (type address) ERC20 token address (0 for native token)
     * @param _amount (type uint256) amount of token to be withdrawn
     */
    function recover(
        address to,
        address _token,
        uint256 _amount
    ) public onlyOwner returns (bool success) {
        if (_token == address(0)) {
            (bool result, ) = to.call{ value: _amount }("");
            return result;
        }
        IERC20(_token).transfer(to, _amount);
        return true;
    }
}
