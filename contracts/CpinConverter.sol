// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/utils/Pausable.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

contract CpinConverter is ReentrancyGuard, AccessControl, Pausable {
    event CDATAConverted(address indexed account, uint256 cdataAmount, uint256 cpinAmount);
    event CWATTConverted(address indexed account, uint256 cwattAmount, uint256 cpinAmount);

    bytes32 public constant PAUSER_ROLE = keccak256("PAUSER_ROLE");
    bytes32 public constant UPDATER_ROLE = keccak256("UPDATER_ROLE");

    IERC20 public immutable CDATAToken;
    IERC20 public immutable CWATTToken;

    mapping(address => uint256) public cdataExchangeRates; // for every 1_000_000 CDATA, how many X token
    mapping(address => uint256) public cwattExchangeRates; // for every 1_000_000 CWATT, how many X token

    constructor(IERC20 _CDATAToken, IERC20 _CWATTToken) {
        CDATAToken = _CDATAToken;
        CWATTToken = _CWATTToken;
        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _grantRole(PAUSER_ROLE, msg.sender);
        _grantRole(UPDATER_ROLE, msg.sender);
    }

    //////////  SETTERS ///////////
    function setCdataExchangeRate(
        address currency,
        uint256 _exchangeRate
    ) public onlyRole(UPDATER_ROLE) {
        cdataExchangeRates[currency] = _exchangeRate;
    }

    function setCwattExchangeRate(
        address currency,
        uint256 _exchangeRate
    ) public onlyRole(UPDATER_ROLE) {
        cwattExchangeRates[currency] = _exchangeRate;
    }
    /////////////////////////////////

    function convertCDATA(
        address currency,
        uint256 cdataAmount
    ) public nonReentrant whenNotPaused returns (bool sucess) {
        uint256 exchangeRate = cdataExchangeRates[currency];
        require(exchangeRate > 0, "invalid currency");
        CDATAToken.transferFrom(msg.sender, address(this), cdataAmount);
        uint256 outputAmount = (cdataAmount * exchangeRate) / 1_000_000;
        SafeERC20.safeTransfer(IERC20(currency), msg.sender, outputAmount);
        return true;
    }

    function convertCWATT(
        address currency,
        uint256 cwattAmount
    ) public nonReentrant whenNotPaused returns (bool sucess) {
        uint256 exchangeRate = cwattExchangeRates[currency];
        require(exchangeRate > 0, "invalid currency");
        CWATTToken.transferFrom(msg.sender, address(this), cwattAmount);
        uint256 outputAmount = (cwattAmount * exchangeRate) / 1_000_000;
        SafeERC20.safeTransfer(IERC20(currency), msg.sender, outputAmount);
        return true;
    }

    /**
     * @param _token (type address) ERC20 token address (can be buyCurrency)
     * @param _amount (type uint256) amount of buyCurrency
     */
    function withdraw(
        address to,
        address _token,
        uint256 _amount
    ) public onlyRole(DEFAULT_ADMIN_ROLE) returns (bool success) {
        if (_token == address(0)) {
            (bool result, ) = to.call{ value: _amount }("");
            return result;
        }
        IERC20(_token).transfer(to, _amount);
        return true;
    }

    /////////
    function pause() public onlyRole(PAUSER_ROLE) {
        _pause();
    }

    function unpause() public onlyRole(PAUSER_ROLE) {
        _unpause();
    }

    function supportsInterface(
        bytes4 interfaceId
    ) public view override(AccessControl) returns (bool) {
        return super.supportsInterface(interfaceId);
    }
}
