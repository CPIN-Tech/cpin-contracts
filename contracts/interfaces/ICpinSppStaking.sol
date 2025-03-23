// SPDX-License-Identifier: MIT

pragma solidity ^0.8.3;

import "./ICpinVirtualPanel.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

interface ICpinSppStaking is IERC721Receiver {
    event SppCreated(uint256 sppId, uint32 startTime, string infoIpfsCid);
    event DidRegistered(uint256 sppId, uint256 didAccountPubKey);
    event DidUnregistered(uint256 sppId, uint256 didAccountPubKey);
    event SppIpfsCidUpdated(uint256 sppId, string ipfsCid);
    event ProductionInfoAdded(
        uint256 sppId,
        uint32 timestamp,
        uint128 productionW,
        uint128 cdataAmount,
        uint128 cwattAmount
    );
    event TokenWithdrawn(uint256 tokenId, uint256 sppId, uint128 capacity);
    event RewardCollected(
        uint256 tokenId,
        uint256 sppId,
        address owner,
        uint128 cdataAmount,
        uint128 cwattAmount
    );
    event TokenStaked(uint256 tokenId, uint256 sppId, uint128 capacity);

    function nft() external view returns (ICpinVirtualPanel);
    function CDATAToken() external view returns (IERC20);
    function CWATTToken() external view returns (IERC20);

    function sppDatas(
        uint256 sppId
    )
        external
        view
        returns (
            uint128 totalStakedCapacity,
            uint32 startTime,
            uint32 numberOfStakes,
            uint32 lastUpdateTime,
            uint32 maxCapacity,
            uint128 rewardIndexCDATA,
            uint128 rewardIndexCWATT
        );

    function sppIpfsCids(uint256 sppId) external view returns (string memory);

    function tokenIdToSppId(uint256 tokenId) external view returns (uint256 sppId);

    function tokenRewardIndexes(
        uint256 tokenId,
        uint256 sppId
    ) external view returns (uint128 valueCDATA, uint128 valueCWATT);

    function tokenEarnedValues(
        uint256 tokenId,
        uint256 sppId
    ) external view returns (uint128 valueCDATA, uint128 valueCWATT);

    function addSpp(
        uint256 sppId,
        uint32 startTime,
        uint32 maxCapacity,
        string memory infoIpfsCid
    ) external;

    function registerDid(uint256 sppId, uint256 didAccountPubKey) external;
    function unregisterDid(uint256 sppId, uint256 didAccountPubKey) external;
    function getSppDidCount(uint256 sppId) external view returns (uint256);
    function getSppDidByIndex(uint256 sppId, uint256 index) external view returns (uint256);

    function updateSppIpfsCid(uint256 sppId, string memory ipfsCid) external;

    function addSppProductionInfo(
        uint256 sppId,
        uint32 previousUpdateTime,
        uint32 timestamp,
        uint128 productionW,
        uint128 cdataAmount,
        uint128 cwattAmount
    ) external;

    function withdrawToken(uint256 tokenId, address owner, bytes memory data) external;

    function collectReward(uint256 tokenId) external;

    function balanceOf(address owner) external view returns (uint256);

    function tokenOfOwnerByIndex(address owner, uint256 index) external view returns (uint256);

    function calculateRewardsEarned(
        uint256 tokenId,
        uint256 sppId
    ) external view returns (uint128 earnedCdata, uint128 earnedCwatt);
}
