// SPDX-License-Identifier: MIT

pragma solidity ^0.8.3;

import "../interfaces/INonTransferrableToken.sol";

/**
 * A non-transferrable tokeN
 */
contract NonTransferrableToken is INonTransferrableToken {
    string private _name;
    string private _symbol;
    uint8 private immutable _decimals;

    uint256 private _totalSupply;
    mapping(address => uint256) private _balances;

    /**
     * @dev Sets the values for `name`, `symbol`, and `decimals`. All three of
     * these values are immutable: they can only be set once during
     * construction.
     */
    constructor(string memory name_, string memory symbol_, uint8 decimals_) {
        _name = name_;
        _symbol = symbol_;
        _decimals = decimals_;
    }

    function name() public view override returns (string memory) {
        return _name;
    }

    function symbol() public view override returns (string memory) {
        return _symbol;
    }

    function decimals() public view override returns (uint8) {
        return _decimals;
    }

    function totalSupply() public view virtual override returns (uint256) {
        return _totalSupply;
    }

    function balanceOf(address _account) public view virtual override returns (uint256) {
        return _balances[_account];
    }

    function _mintBalance(address _address, uint256 _amount) internal {
        _totalSupply += _amount;
        _balances[_address] += _amount;
        emit Transfer(address(0), _address, _amount);
    }

    function _burnBalance(address _address, uint256 _amount) internal {
        _totalSupply -= _amount;
        _balances[_address] -= _amount;
        emit Transfer(_address, address(0), _amount);
    }
}
