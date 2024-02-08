// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "./interfaces/ICryptolygonIdleV1.sol";

import "@openzeppelin/contracts-upgradeable/utils/PausableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

/// @custom:security-contact
contract CryptolygonIdleV1 is ICryptolygonIdleV1, Initializable, PausableUpgradeable, OwnableUpgradeable, UUPSUpgradeable {
    using BigNumber for BigNumber;

    mapping (address => PlayerDataV1) public playersData;

    IERC20 constant public CIRCLE = IERC20(0x0);

    // Admin functions

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() {
        _disableInitializers();
    }

    function initialize(address initialOwner) initializer public {
        __Pausable_init();
        __Ownable_init(initialOwner);
        __UUPSUpgradeable_init();
    }

    function pause() public onlyOwner {
        _pause();
    }

    function unpause() public onlyOwner {
        _unpause();
    }

    function _authorizeUpgrade(address newImplementation)
        internal
        onlyOwner
        override
    {}

    // Game external functions

    /**
     * @inheritdoc ICryptolygonIdleV1
     */
    function levelUpPolygons(uint256[] calldata polygonIds, uint256[] calldata amounts) external returns() {
        require(polygonIds.length == amounts.length, InvalidArguments);
        require(polygonIds.length > 0, InvalidArguments);
    }

    /**
     * @inheritdoc ICryptolygonIdleV1
     */
    function buyUpgrades(uint256[] calldata upgradeIds, uint256[] calldata amounts) external returns() {
        require(upgradeIds.length == amounts.length, InvalidArguments);
        require(upgradeIds.length > 0, InvalidArguments);
    }

    /**
     * @inheritdoc ICryptolygonIdleV1
     */
    function buyAscensionPerks(uint256[] calldata perkIds, uint256[] calldata amounts) external returns() {
        require(perkIds.length == amounts.length, InvalidArguments);
        require(perkIds.length > 0, InvalidArguments);
    }

    /**
     * @inheritdoc ICryptolygonIdleV1
     */
    function ascend() external receive() {
    }

    /**
     * @inheritdoc ICryptolygonIdleV1
     */
    function tip() external payable() {
        payable(owner()).transfer(msg.value);
    }

    // Public functions

    /**
     * @inheritdoc ICryptolygonIdleV1
     */
    function getPlayerLinesPerSecond(address player) public view returns (BigNumber memory) {
    }

    /**
     * @inheritdoc ICryptolygonIdleV1
     */
    function getPlayerLines(address player) public view returns (BigNumber memory) {
    }

    // Internal functions

    /**
     * @inheritdoc ICryptolygonIdleV1
     */
    function _levelUpPolygon(uint256 polygonId, uint256 amount) internal {
    }

    /**
     * @inheritdoc ICryptolygonIdleV1
     */
    function _buyUpgrade(uint256 upgradeId, uint256 amount) internal {
    }

    /**
     * @inheritdoc ICryptolygonIdleV1
     */
    function _buyAscensionPerk(uint256 perkId, uint256 amount) internal {
    }

    /**
     * @inheritdoc ICryptolygonIdleV1
     */
    function _updatePlayerData() internal {
        memory PlayerDataV1 storage playerData = playersData[msg.sender];
        playersData[msg.sender].lastUpdateTime = block.timestamp;

        // Compute the player's lines per second
        BigNumber memory linesPerSecond = BigNumber.init(0, false);

        for (uint256 i = 1; i < playerData.levelOfPolygons.length - 1; i++) {
            uint256 basePolygonLinesPerSecond = 2**i;

            uint256 polygonLevel = playerData.levelOfPolygons[i];
            uint256 polygonLevelMultiplier = (1 + 2*(polygonLevel/50)) * (1 + 5*(polygonLevel/500));

            uint256 normalUpgradesMultiplier = 1;

            uint256 ascensionUpgradesMultiplier = 1;

            BigNumber memory polygonLinesPerSecond = BigNumber.init(basePolygonLinesPerSecond, false)
                .mul(BigNumber.init(polygonLevel, false))
                .mul(BigNumber.init(polygonLevelMultiplier, false))
                .mul(BigNumber.init(normalUpgradesMultiplier, false))
                .mul(BigNumber.init(ascensionUpgradesMultiplier, false));

            linesPerSecond = linesPerSecond.add(polygonLinesPerSecond);
        }

        // Compute the player's lines
        uint256 timePassed = block.timestamp - playerData.lastUpdateTime;
        BigNumber memory newLinesSinceLastUpdate = linesPerSecond.mul(BigNumber.init(timePassed, false));

        // Update the player's data
        playersData[msg.sender].linesLastUpdate = playerData.lines.add(newLinesSinceLastUpdate);
        playersData[msg.sender].totalLines = playerData.totalLines.add(newLinesSinceLastUpdate);
    }

}