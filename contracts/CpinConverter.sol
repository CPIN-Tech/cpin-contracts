// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/utils/Pausable.sol";

contract CpinConverter is ReentrancyGuard, AccessControl, Pausable {
    event CDATAConverted(address indexed account, uint256 cdataAmount, uint256 cpinAmount);
    event CWATTConverted(address indexed account, uint256 cwattAmount, uint256 cpinAmount);

    bytes32 public constant PAUSER_ROLE = keccak256("PAUSER_ROLE");
    bytes32 public constant UPDATER_ROLE = keccak256("UPDATER_ROLE");

    IERC20 public immutable CPINToken;
    IERC20 public immutable CDATAToken;
    IERC20 public immutable CWATTToken;

    uint256 public cdataExchangeRate; // for every 1_000_000 CDATA, how many CPIN
    uint256 public cwattExchangeRate; // for every 1_000_000 CWATT, how many CPIN

    constructor(
        IERC20 _CPINToken,
        IERC20 _CDATAToken,
        IERC20 _CWATTToken,
        uint256 _cdataExchangeRate,
        uint256 _cwattExchangeRate
    ) {
        CPINToken = _CPINToken;
        CDATAToken = _CDATAToken;
        CWATTToken = _CWATTToken;
        cdataExchangeRate = _cdataExchangeRate;
        cwattExchangeRate = _cwattExchangeRate;
        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _grantRole(PAUSER_ROLE, msg.sender);
        _grantRole(UPDATER_ROLE, msg.sender);
    }

    //////////  SETTERS ///////////
    function setCdataExchangeRate(uint256 _exchangeRate) public onlyRole(UPDATER_ROLE) {
        cdataExchangeRate = _exchangeRate;
    }
    function setCwattExchangeRate(uint256 _exchangeRate) public onlyRole(UPDATER_ROLE) {
        cwattExchangeRate = _exchangeRate;
    }
    /////////////////////////////////

    function convertCDATA(uint256 amount) public nonReentrant whenNotPaused returns (bool sucess) {
        CDATAToken.transferFrom(msg.sender, address(this), amount);
        uint256 cpinAmount = (amount * cdataExchangeRate) / 1_000_000;
        CPINToken.transfer(msg.sender, cpinAmount);
        return true;
    }

    function convertCWATT(uint256 amount) public nonReentrant whenNotPaused returns (bool sucess) {
        CWATTToken.transferFrom(msg.sender, address(this), amount);
        uint256 cpinAmount = (amount * cwattExchangeRate) / 1_000_000;
        CPINToken.transfer(msg.sender, cpinAmount);
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
