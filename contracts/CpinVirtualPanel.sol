// SPDX-License-Identifier: MIT
// Compatible with OpenZeppelin Contracts ^5.0.0
pragma solidity ^0.8.20;

import "./interfaces/ICpinVirtualPanel.sol";
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Burnable.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";

contract CpinVirtualPanel is
    ERC721,
    ERC721Enumerable,
    ERC721Burnable,
    AccessControl,
    ICpinVirtualPanel
{
    bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");
    uint256 private _nextTokenId = 1;
    string private baseUrl = "https://api.cpin.tech/nft/virtual-panels/";

    // tokenId => panelInfo
    mapping(uint256 => PanelInfo) public override panelInfos;

    constructor(address defaultAdmin) ERC721("CpinVirtualPanel", "CPIN-VP") {
        _grantRole(DEFAULT_ADMIN_ROLE, defaultAdmin);
        _grantRole(MINTER_ROLE, defaultAdmin);
    }

    function _baseURI() internal view override returns (string memory) {
        return baseUrl;
    }

    function updateBaseURI(string memory uri) external override onlyRole(DEFAULT_ADMIN_ROLE) {
        baseUrl = uri;
    }

    function safeMint(
        address to,
        uint128 capacity,
        uint32 expireDate
    ) public override onlyRole(MINTER_ROLE) {
        require(to != address(0), "invalid address");
        require(capacity > 0, "invalid capacity");
        require(expireDate > (block.timestamp + 7 days));
        uint256 tokenId = _nextTokenId++;
        panelInfos[tokenId] = PanelInfo(capacity, expireDate);
        _safeMint(to, tokenId);
        emit PanelInfoUpdated(tokenId, capacity, expireDate);
    }

    function splitToken(uint256 tokenId, uint128[] memory capacities) public override {
        require(ownerOf(tokenId) == msg.sender, "only owner");
        require(capacities.length > 1, "invalid capacity");
        PanelInfo memory info = panelInfos[tokenId];
        require(info.expireDate > block.timestamp, "token expired");
        uint128 totalCapacity = 0;
        uint256[] memory newTokenIds = new uint256[](capacities.length);
        for (uint256 i = 0; i < capacities.length; i++) {
            uint128 capacity = capacities[i];
            totalCapacity += capacity;
            uint256 newTokenId = _nextTokenId++;
            panelInfos[newTokenId] = PanelInfo(capacity, info.expireDate);
            _safeMint(msg.sender, newTokenId);
            newTokenIds[i] = newTokenId;
            emit PanelInfoUpdated(newTokenId, capacity, info.expireDate);
        }
        require(totalCapacity == info.capacity, "wrong total capacity");
        _burn(tokenId);
        delete panelInfos[tokenId];
        emit TokenSplited(msg.sender, tokenId, capacities, newTokenIds);
    }

    function mergeTokens(uint256[] memory tokenIds) public override {
        require(tokenIds.length > 0, "empty array");
        uint128 totalCapacity = 0;
        uint32 minExpireDate = type(uint32).max;
        for (uint256 i = 0; i < tokenIds.length; i++) {
            uint256 tid = tokenIds[i];
            require(ownerOf(tid) == msg.sender, "only owner");
            PanelInfo memory info = panelInfos[tid];
            require(info.expireDate > block.timestamp, "token expired");
            totalCapacity += info.capacity;
            if (info.expireDate < minExpireDate) {
                minExpireDate = info.expireDate;
            }
            burn(tid);
            delete panelInfos[tid];
        }
        uint256 tokenId = _nextTokenId++;
        panelInfos[tokenId] = PanelInfo(totalCapacity, minExpireDate);
        _safeMint(msg.sender, tokenId);
        emit PanelInfoUpdated(tokenId, totalCapacity, minExpireDate);
        emit TokensMerged(msg.sender, tokenIds, tokenId);
    }

    // The following functions are overrides required by Solidity.

    function _update(
        address to,
        uint256 tokenId,
        address auth
    ) internal override(ERC721, ERC721Enumerable) returns (address) {
        return super._update(to, tokenId, auth);
    }

    function _increaseBalance(
        address account,
        uint128 value
    ) internal override(ERC721, ERC721Enumerable) {
        super._increaseBalance(account, value);
    }

    function supportsInterface(
        bytes4 interfaceId
    ) public view override(ERC721, ERC721Enumerable, AccessControl) returns (bool) {
        return super.supportsInterface(interfaceId);
    }
}
