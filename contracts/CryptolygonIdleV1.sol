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
    using BigNumbers for *;

    mapping(address => PlayerDataV1) public playersData;

    IERC20 constant public CIRCLE = IERC20(address(0));

    // Errors

    /**
     * @dev Error thrown when the arguments are invalid.
     */
    error InvalidArguments();

    /**
     * @dev Error thrown when leveling up a polygon is not allowed.
     * @param polygonId The ID of the polygon.
     * @param amountOfLevels The number of levels requested.
     */
    error PolygonLevelUpNotAllowed(uint256 polygonId, uint256 amountOfLevels);

    /**
     * @dev Error thrown when there are not enough lines to level up a polygon.
     * @param polygonId The ID of the polygon.
     * @param amountOfLevels The number of levels requested.
     */
    error NotEnoughLinesToLevelUp(uint256 polygonId, uint256 amountOfLevels);

    /**
     * @dev Error thrown when buying an upgrade is not allowed.
     * @param upgradeId The ID of the upgrade.
     * @param amountOfLevels The number of levels requested.
     */
    error UpgradeNotAllowed(uint256 upgradeId, uint256 amountOfLevels);
    
    /**
     * @dev Error thrown when there are not enough lines to buy an upgrade.
     * @param upgradeId The ID of the upgrade.
     * @param amountOfLevels The amount of levels needed to buy the upgrade.
     */
    error NotEnoughLinesToBuyUpgrade(uint256 upgradeId, uint256 amountOfLevels);

    /**
     * @dev Error thrown when an ascension perk is not allowed.
     * @param perkId The ID of the perk.
     * @param amountOfLevels The amount of levels needed to buy the perk.
     */
    error AscensionPerkNotAllowed(uint256 perkId, uint256 amountOfLevels);

    /**
     * @dev Error thrown when there are not enough circles to buy a perk.
     * @param perkId The ID of the perk.
     * @param amountOfLevels The amount of levels needed to buy the perk.
     */
    error NotEnoughCirclesToBuyPerk(uint256 perkId, uint256 amountOfLevels);

    /**
     * @dev Error thrown when ascension is not allowed.
     */
    error AscensionNotAllowed();

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
    function levelUpPolygons(uint256[] calldata polygonIds, uint256[] calldata amounts) external {
        if (polygonIds.length != amounts.length || polygonIds.length == 0) {
            revert InvalidArguments();
        }
    }

    /**
     * @inheritdoc ICryptolygonIdleV1
     */
    function buyUpgrades(uint256[] calldata upgradeIds, uint256[] calldata amounts) external {
        if (upgradeIds.length != amounts.length || upgradeIds.length == 0) {
            revert InvalidArguments();
        }
    }

    /**
     * @inheritdoc ICryptolygonIdleV1
     */
    function buyAscensionPerks(uint256[] calldata perkIds, uint256[] calldata amounts) external {
        if (perkIds.length != amounts.length || perkIds.length == 0) {
            revert InvalidArguments();
        }
    }

    /**
     * @inheritdoc ICryptolygonIdleV1
     */
    function ascend() external {
    }

    /**
     * @inheritdoc ICryptolygonIdleV1
     */
    function tip() external payable {
        payable(owner()).transfer(msg.value);
    }

    // Public functions

    /**
     * @dev Function to get the player lines per second, computed using the player's data.
     * @param player The address of the player.
     */
    function getPlayerLinesPerSecond(address player) public view returns (BigNumber memory) {
        PlayerDataV1 memory playerData = playersData[player];

        // Compute the player's lines per second
        BigNumber memory linesPerSecond = BigNumbers.init(0, false);

        for (uint256 i = 1; i < playerData.levelOfPolygons.length - 1; i++) {
            uint256 basePolygonLinesPerSecond = 2**i;

            uint256 polygonLevel = playerData.levelOfPolygons[i];
            uint256 polygonLevelMultiplier = (1 + 2*(polygonLevel/50)) * (1 + 5*(polygonLevel/500));

            uint256 normalUpgradesMultiplier = 1;

            uint256 ascensionUpgradesMultiplier = 1;

            BigNumber memory polygonLinesPerSecond = BigNumbers.init(basePolygonLinesPerSecond, false)
                .mul(BigNumbers.init(polygonLevel, false))
                .mul(BigNumbers.init(polygonLevelMultiplier, false))
                .mul(BigNumbers.init(normalUpgradesMultiplier, false))
                .mul(BigNumbers.init(ascensionUpgradesMultiplier, false));

            linesPerSecond = linesPerSecond.add(polygonLinesPerSecond);
        }

        return linesPerSecond;
    }

    /**
     * @dev Function to get the player lines, computed using the player's data.
     * @param player The address of the player.
     */
    function getPlayerLines(address player) public view returns (BigNumber memory) {
        PlayerDataV1 memory playerData = playersData[player];

        // Compute the player's lines
        uint256 timePassed = block.timestamp - playerData.timestampLastUpdate;
        BigNumber memory newLinesSinceLastUpdate = getPlayerLinesPerSecond(player).mul(BigNumbers.init(timePassed, false));

        return playerData.linesLastUpdate.add(newLinesSinceLastUpdate);
    }

    // Internal functions

    /**
     * @dev Internal function to level up a polygon.
     * @param polygonId The id of the polygon to level up.
     * @param amount The amount to level up the polygon.
     * 
     * Requirements:
     * - The previous polygon (polygonId - 1) must be at least at level 1 (except for polygonId = 1)
     * - The player must have enough lines to level up the polygon.
     */
    function _levelUpPolygon(uint256 polygonId, uint256 amount) internal {
    }

    /**
     * @dev Internal function to buy an upgrade.
     * @param upgradeId The id of the upgrade to buy.
     * @param amount The amount to buy the upgrade.
     * 
     * Requirements:
     * - The previous upgrade (upgradeId - 1) must be at least at level 1 (except for upgradeId = 0)
     * - The player must have enough lines to buy the upgrade.
     */
    function _buyUpgrade(uint256 upgradeId, uint256 amount) internal {
    }

    /**
     * @dev Internal function to buy an ascension perk.
     * @param perkId The id of the ascension perk to buy.
     * @param amount The amount to buy the ascension perk.
     * 
     * Requirements:
     * - The previous ascension perk (perkId - 1) must be at least at level 1 (except for perkId = 0)
     * - The player must have enough circles to buy the ascension perk.
     */
    function _buyAscensionPerk(uint256 perkId, uint256 amount) internal {
    }

    /**
     * @dev Internal function to update the player data, including the number of lines and the timestamp of the last update, as well as the total number of lines of all time. Should be called before any action that affects the player's data.
     * NOTE : Not using getPlayerLinesPerSecond and getPlayerLines to avoid gas costs
     */
    function _updatePlayerData() internal {
        PlayerDataV1 memory playerData = playersData[msg.sender];
        playersData[msg.sender].timestampLastUpdate = block.timestamp;

        // Compute the player's lines per second
        BigNumber memory linesPerSecond = BigNumbers.init(0, false);

        for (uint256 i = 1; i < playerData.levelOfPolygons.length - 1; i++) {
            uint256 basePolygonLinesPerSecond = 2**i;

            uint256 polygonLevel = playerData.levelOfPolygons[i];
            uint256 polygonLevelMultiplier = (1 + 2*(polygonLevel/50)) * (1 + 5*(polygonLevel/500));

            uint256 normalUpgradesMultiplier = 1;

            uint256 ascensionUpgradesMultiplier = 1;

            BigNumber memory polygonLinesPerSecond = BigNumbers.init(basePolygonLinesPerSecond, false)
                .mul(BigNumbers.init(polygonLevel, false))
                .mul(BigNumbers.init(polygonLevelMultiplier, false))
                .mul(BigNumbers.init(normalUpgradesMultiplier, false))
                .mul(BigNumbers.init(ascensionUpgradesMultiplier, false));

            linesPerSecond = linesPerSecond.add(polygonLinesPerSecond);
        }

        // Compute the player's lines
        uint256 timePassed = block.timestamp - playerData.timestampLastUpdate;
        BigNumber memory newLinesSinceLastUpdate = linesPerSecond.mul(BigNumbers.init(timePassed, false));

        // Update the player's data
        playersData[msg.sender].linesLastUpdate = playerData.linesLastUpdate.add(newLinesSinceLastUpdate);
        playersData[msg.sender].totalLines = playerData.totalLines.add(newLinesSinceLastUpdate);
    }

}