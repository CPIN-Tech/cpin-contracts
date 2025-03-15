// SPDX-License-Identifier: MIT
// Compatible with OpenZeppelin Contracts ^5.0.0
pragma solidity ^0.8.20;

import "@openzeppelin/contracts-upgradeable/access/AccessControlUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "./interfaces/ICpinVirtualPanel.sol";

contract CpinBuyPanel is Initializable, AccessControlUpgradeable {
    bytes32 public constant UPDATER_ROLE = keccak256("UPDATER_ROLE");

    ICpinVirtualPanel public panelContract;

    mapping(address => uint256) public prices;

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() {
        _disableInitializers();
    }

    function initialize(address defaultAdmin, address _panelContract) public initializer {
        __AccessControl_init();
        _grantRole(DEFAULT_ADMIN_ROLE, defaultAdmin);
        _grantRole(UPDATER_ROLE, defaultAdmin);
        panelContract = ICpinVirtualPanel(_panelContract);
    }

    function updatePrice(address currency, uint256 price) public onlyRole(UPDATER_ROLE) {
        prices[currency] = price;
    }

    function buyPanel(address currency, uint256 capacity) public {
        require(prices[currency] > 0, "invalid currency");
        require(capacity > 0 && capacity <= 1000, "invalid capacity");
        uint256 price = capacity * prices[currency];
        SafeERC20.safeTransferFrom(IERC20(currency), msg.sender, address(this), price);
        panelContract.safeMint(msg.sender, uint128(capacity), uint32(block.timestamp + (180 days)));
    }

    function buyPanelNative(uint256 capacity) public payable {
        require(prices[0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE] > 0, "no native price");
        require(capacity > 0 && capacity <= 1000, "invalid capacity");
        uint256 price = capacity * prices[0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE];
        require(msg.value >= price, "invalid amount");
        panelContract.safeMint(msg.sender, uint128(capacity), uint32(block.timestamp + (180 days)));
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
        require(to != address(0), "invalid to");
        if (_token == address(0) || _token == 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE) {
            (bool result, ) = to.call{ value: _amount }("");
            return result;
        }
        SafeERC20.safeTransfer(IERC20(_token), to, _amount);
        return true;
    }
}
