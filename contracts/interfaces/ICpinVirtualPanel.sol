// SPDX-License-Identifier: MIT

pragma solidity ^0.8.3;

import "@openzeppelin/contracts/token/ERC721/extensions/IERC721Enumerable.sol";
import "@openzeppelin/contracts/access/IAccessControl.sol";

interface ICpinVirtualPanel {
    event PanelInfoUpdated(uint256 indexed tokenId, uint128 capacity, uint32 expireDate);
    event TokenSplited(
        address indexed account,
        uint256 indexed tokenId,
        uint128[] capacities,
        uint256[] newTokenIds
    );
    event TokensMerged(address indexed account, uint256[] tokenIds, uint256 newTokenId);

    struct PanelInfo {
        uint128 capacity;
        uint32 expireDate;
    }

    function updateBaseURI(string memory uri) external;

    function panelInfos(
        uint256 tokenId
    ) external view returns (uint128 capacity, uint32 expireDate);

    function safeMint(address to, uint128 capacity, uint32 expireDate) external;

    function splitToken(uint256 tokenId, uint128[] memory capacities) external;

    function mergeTokens(uint256[] memory tokenIds) external;
}
