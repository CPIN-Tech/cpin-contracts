// SPDX-License-Identifier: MIT
// Compatible with OpenZeppelin Contracts ^5.0.0
pragma solidity ^0.8.20;
pragma abicoder v2;

import "./interfaces/ICpinSppStaking.sol";
import "./interfaces/ICpinVirtualPanel.sol";

import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts-upgradeable/access/AccessControlUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/utils/MulticallUpgradeable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

/// @title Stake Cpin Virtual Panels to SPP's and get CDATA and CWATT tokens
contract CpinSppStaking is
    Initializable,
    ICpinSppStaking,
    AccessControlUpgradeable,
    MulticallUpgradeable
{
    using EnumerableSet for EnumerableSet.UintSet;

    bytes32 public constant SPP_MANAGER_ROLE = keccak256("SPP_MANAGER_ROLE");
    bytes32 public constant DATA_UPDATER_ROLE = keccak256("DATA_UPDATER_ROLE");

    struct SppData {
        uint128 totalStakedCapacity;
        uint32 startTime;
        uint32 numberOfStakes;
        uint32 lastUpdateTime;
        uint32 maxCapacity;
        // ----------
        uint128 rewardIndexCDATA;
        uint128 rewardIndexCWATT;
    }

    struct TokenRewardInfo {
        uint128 valueCDATA;
        uint128 valueCWATT;
    }

    ICpinVirtualPanel public override nft;
    IERC20 public override CDATAToken;
    IERC20 public override CWATTToken;

    /// @dev sppId => SppData
    mapping(uint256 => SppData) public override sppDatas;

    /// @dev sppId => ipfs cid
    mapping(uint256 => string) public override sppIpfsCids;

    /// @dev sppId => peaq did set
    mapping(uint256 => EnumerableSet.UintSet) private sppDids;

    /// @dev tokenId => sppId
    mapping(uint256 => uint256) public override tokenIdToSppId;

    /// @dev tokenId => sppId => RewardIndexes
    mapping(uint256 => mapping(uint256 => TokenRewardInfo)) public override tokenRewardIndexes;

    /// @dev tokenId => sppId => TokenEarnedValues
    mapping(uint256 => mapping(uint256 => TokenRewardInfo)) public override tokenEarnedValues;

    /// @dev account => staked tokens set
    mapping(address => EnumerableSet.UintSet) private userStakedTokens;

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() {
        _disableInitializers();
    }

    function initialize(
        address defaultAdmin,
        ICpinVirtualPanel _nft,
        IERC20 _CDATAToken,
        IERC20 _CWATTToken
    ) public initializer {
        __AccessControl_init();
        __Multicall_init();

        nft = _nft;
        CDATAToken = _CDATAToken;
        CWATTToken = _CWATTToken;

        _grantRole(DEFAULT_ADMIN_ROLE, defaultAdmin);
        _grantRole(SPP_MANAGER_ROLE, defaultAdmin);
        _grantRole(DATA_UPDATER_ROLE, defaultAdmin);
    }

    function addSpp(
        uint256 sppId,
        uint32 startTime,
        uint32 maxCapacity,
        string memory infoIpfsCid
    ) external override onlyRole(SPP_MANAGER_ROLE) {
        require(sppId > 0, "id must be positive");
        require(sppDatas[sppId].startTime == 0, "SPP already exists");
        require(block.timestamp <= startTime, "startTime must be after now");
        require(bytes(infoIpfsCid).length > 0, "empty ipfs cid");

        sppDatas[sppId] = SppData({
            totalStakedCapacity: 0,
            startTime: startTime,
            numberOfStakes: 0,
            lastUpdateTime: startTime,
            maxCapacity: maxCapacity,
            rewardIndexCDATA: 0,
            rewardIndexCWATT: 0
        });
        sppIpfsCids[sppId] = infoIpfsCid;

        emit SppCreated(sppId, startTime, infoIpfsCid);
    }

    function registerDid(
        uint256 sppId,
        uint256 didAccountPubKey
    ) external override onlyRole(SPP_MANAGER_ROLE) {
        require(sppDatas[sppId].startTime > 0, "SPP not found");
        require(didAccountPubKey != 0, "invalid address");
        require(sppDids[sppId].contains(didAccountPubKey) == false, "already registered");
        sppDids[sppId].add(didAccountPubKey);
        emit DidRegistered(sppId, didAccountPubKey);
    }

    function unregisterDid(
        uint256 sppId,
        uint256 didAccountPubKey
    ) external override onlyRole(SPP_MANAGER_ROLE) {
        require(sppDatas[sppId].startTime > 0, "SPP not found");
        require(sppDids[sppId].contains(didAccountPubKey), "did not found");
        sppDids[sppId].remove(didAccountPubKey);
        emit DidUnregistered(sppId, didAccountPubKey);
    }

    function getSppDidCount(uint256 sppId) external view override returns (uint256) {
        return sppDids[sppId].length();
    }
    function getSppDidByIndex(
        uint256 sppId,
        uint256 index
    ) external view override returns (uint256) {
        return sppDids[sppId].at(index);
    }

    function updateSppIpfsCid(
        uint256 sppId,
        string memory ipfsCid
    ) public override onlyRole(SPP_MANAGER_ROLE) {
        sppIpfsCids[sppId] = ipfsCid;
        emit SppIpfsCidUpdated(sppId, ipfsCid);
    }

    function addSppProductionInfo(
        uint256 sppId,
        uint32 previousUpdateTime,
        uint32 timestamp,
        uint128 productionW,
        uint128 cdataAmount,
        uint128 cwattAmount
    ) public onlyRole(DATA_UPDATER_ROLE) {
        require(timestamp < block.timestamp, "time must be before now");
        SppData memory data = sppDatas[sppId];
        require(data.startTime > 0, "non-existent SPP");
        require(data.lastUpdateTime == previousUpdateTime, "invalid previousUpdateTime");

        if (cdataAmount > 0 && data.totalStakedCapacity > 0) {
            data.rewardIndexCDATA += cdataAmount / data.totalStakedCapacity;
            SafeERC20.safeTransferFrom(CDATAToken, msg.sender, address(this), cdataAmount);
        }
        if (cwattAmount > 0 && data.totalStakedCapacity > 0) {
            data.rewardIndexCWATT += cwattAmount / data.totalStakedCapacity;
            SafeERC20.safeTransferFrom(CWATTToken, msg.sender, address(this), cwattAmount);
        }
        data.lastUpdateTime = timestamp;
        sppDatas[sppId] = data;

        emit ProductionInfoAdded(sppId, timestamp, productionW, cdataAmount, cwattAmount);
    }

    /// @inheritdoc IERC721Receiver
    function onERC721Received(
        address,
        address from,
        uint256 tokenId,
        bytes calldata data
    ) external override returns (bytes4) {
        require(msg.sender == address(nft), "not a cpin virtual panel nft");
        require(data.length > 0, "no data provided");

        _stakeToken(tokenId, abi.decode(data, (uint256)), from);
        return this.onERC721Received.selector;
    }

    function withdrawToken(uint256 tokenId, address owner, bytes memory data) external override {
        (uint128 capacity, uint32 expireDate) = nft.panelInfos(tokenId);
        require(capacity > 0, "non-existent token");
        require(userStakedTokens[owner].contains(tokenId), "invalid owner");
        if (expireDate > block.timestamp) {
            // if not expired only owner can withdraw, otherwise everyone can withdraw token to the owner
            require(owner == msg.sender, "only owner can collect");
        }

        uint256 sppId = tokenIdToSppId[tokenId];

        _collectReward(tokenId, sppId, owner);

        SppData memory sppData = sppDatas[sppId];
        sppData.totalStakedCapacity -= capacity;
        sppData.numberOfStakes--;
        sppDatas[sppId] = sppData;

        userStakedTokens[owner].remove(tokenId);
        tokenIdToSppId[tokenId] = 0;

        IERC721(address(nft)).safeTransferFrom(address(this), owner, tokenId, data);

        emit TokenWithdrawn(tokenId, sppId, capacity);
    }

    function collectReward(uint256 tokenId) external override {
        require(userStakedTokens[msg.sender].contains(tokenId), "only owner can collect");
        uint256 sppId = tokenIdToSppId[tokenId];
        _collectReward(tokenId, sppId, msg.sender);
    }

    function _collectReward(uint256 tokenId, uint256 sppId, address owner) private {
        _updateRewards(tokenId, sppId);

        TokenRewardInfo memory tokenEarnedInfo = tokenEarnedValues[tokenId][sppId];
        if (tokenEarnedInfo.valueCDATA > 0) {
            SafeERC20.safeTransfer(CDATAToken, owner, tokenEarnedInfo.valueCDATA);
        }
        if (tokenEarnedInfo.valueCWATT > 0) {
            SafeERC20.safeTransfer(CWATTToken, owner, tokenEarnedInfo.valueCWATT);
        }
        tokenEarnedValues[tokenId][sppId] = TokenRewardInfo(0, 0);

        emit RewardCollected(
            tokenId,
            sppId,
            owner,
            tokenEarnedInfo.valueCDATA,
            tokenEarnedInfo.valueCWATT
        );
    }

    function balanceOf(address owner) external view override returns (uint256) {
        return userStakedTokens[owner].length();
    }

    function tokenOfOwnerByIndex(
        address owner,
        uint256 index
    ) external view override returns (uint256) {
        return userStakedTokens[owner].at(index);
    }

    function _calculateRewards(
        uint256 tokenId,
        uint256 sppId
    ) private view returns (uint128 cdataAmount, uint128 cwattAmount) {
        (uint128 capacity, ) = nft.panelInfos(tokenId);
        SppData memory data = sppDatas[sppId];
        TokenRewardInfo memory tokenRewardInfo = tokenRewardIndexes[tokenId][sppId];
        cdataAmount = capacity * (data.rewardIndexCDATA - tokenRewardInfo.valueCDATA);
        cwattAmount = capacity * (data.rewardIndexCWATT - tokenRewardInfo.valueCWATT);
    }

    function calculateRewardsEarned(
        uint256 tokenId,
        uint256 sppId
    ) external view returns (uint128 earnedCdata, uint128 earnedCwatt) {
        (uint128 cdataAmount, uint128 cwattAmount) = _calculateRewards(tokenId, sppId);
        TokenRewardInfo memory tokenEarnedInfo = tokenEarnedValues[tokenId][sppId];
        earnedCdata = tokenEarnedInfo.valueCDATA + cdataAmount;
        earnedCwatt = tokenEarnedInfo.valueCWATT + cwattAmount;
    }

    function _updateRewards(uint256 tokenId, uint256 sppId) private {
        (uint128 cdataAmount, uint128 cwattAmount) = _calculateRewards(tokenId, sppId);
        TokenRewardInfo memory tokenEarnedInfo = tokenEarnedValues[tokenId][sppId];
        tokenEarnedInfo.valueCDATA += cdataAmount;
        tokenEarnedInfo.valueCWATT += cwattAmount;
        tokenEarnedValues[tokenId][sppId] = tokenEarnedInfo;
        tokenRewardIndexes[tokenId][sppId] = TokenRewardInfo(
            sppDatas[sppId].rewardIndexCDATA,
            sppDatas[sppId].rewardIndexCWATT
        );
    }

    function _stakeToken(uint256 tokenId, uint256 sppId, address owner) private {
        (uint128 capacity, uint32 expireDate) = nft.panelInfos(tokenId);
        require(capacity > 0, "non-existent token");
        require(expireDate > block.timestamp, "token expired");
        SppData memory data = sppDatas[sppId];
        require(data.startTime > 0, "non-existent SPP");
        require(data.startTime < block.timestamp, "SPP not started");
        require(data.maxCapacity >= (data.totalStakedCapacity + capacity), "not enough capacity");
        data.totalStakedCapacity += capacity;
        data.numberOfStakes++;
        sppDatas[sppId] = data;

        tokenIdToSppId[tokenId] = sppId;

        tokenRewardIndexes[tokenId][sppId] = TokenRewardInfo(
            data.rewardIndexCDATA,
            data.rewardIndexCWATT
        );

        userStakedTokens[owner].add(tokenId);

        emit TokenStaked(tokenId, sppId, capacity);
    }
}
