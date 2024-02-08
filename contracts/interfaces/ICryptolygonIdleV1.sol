// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "../libraries/BigNumber.sol";

/**
 * @title ICryptolygonIdleV1
 * @dev Interface for the Cryptolygon Idle contract.
 */
interface ICryptolygonIdleV1 {
    
    // Structs

    /**
     * @dev PlayerDataV1 struct to store player data.
     * 
     * @param levelOfPolygons: Array of the level of polygons owned by the player.
     * @param levelOfAscensionPerks: Array of the level of ascension perks for the player.
     * @param polygonsMultiplierUpgrades: Array of the polygons multiplier upgrades for the player.
     * @param timestampLastUpdate: Timestamp of the last update for the player.
     * @param linesLastUpdate: BigNumber of the lines at the last update for the player.
     * @param totalLines: Total number of lines for the player.
     * @param numberOfAscensions: Number of ascensions performed by the players.
     */
    struct PlayerDataV1 {
        uint256[] levelOfPolygons;
        uint256[] levelOfAscensionPerks;
        uint256[] polygonsMultiplierUpgrades;
        uint256 timestampLastUpdate;
        BigNumber linesLastUpdate;
        BigNumber totalLines;
        uint256 numberOfAscensions;
    }

    // Events

    /**
     * @dev Emitted when a polygon is leveled up.
     * @param player The address of the player.
     * @param polygonId The ID of the polygon.
     * @param amountOfLevels The number of levels gained.
     */
    event PolygonLeveledUp(address indexed player, uint256 polygonId, uint256 amountOfLevels);

    /**
     * @dev Emitted when an upgrade is bought.
     * @param player The address of the player.
     * @param upgradeId The ID of the upgrade.
     * @param amountOfLevels The number of levels gained.
     */
    event UpgradeBought(address indexed player, uint256 upgradeId, uint256 amountOfLevels);

    /**
     * @dev Emitted when an ascension perk is bought.
     * @param player The address of the player.
     * @param perkId The ID of the perk.
     * @param amountOfLevels The number of levels gained.
     */
    event AscensionPerkBought(address indexed player, uint256 perkId, uint256 amountOfLevels);

    /**
     * @dev Emitted when a player ascends.
     * @param player The address of the player.
     */
    event Ascended(address indexed player);

    /**
     * @dev Emitted when player data is updated.
     * @param player The address of the player.
     * @param lines The number of lines.
     * @param totalLines The total number of lines.
     */
    event PlayerDataUpdated(address indexed player, BigNumber lines, BigNumber totalLines);

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

    // External functions

    /**
     * @dev Function to level up the polygons in batch.
     * @param polygonIds List of polygon ids to level up.
     * @param amounts List of amounts to level up the polygons.
     */
    function levelUpPolygons(uint256[] calldata polygonIds, uint256[] calldata amounts) external returns();

    /**
     * @dev Function to buy upgrades in batch.
     * @param upgradeIds List of upgrade ids to buy.
     * @param amounts List of amounts to buy the upgrades.
     */
    function buyUpgrades(uint256[] calldata upgradeIds, uint256[] calldata amounts) external returns();

    /**
     * @dev Function to buy ascension perks in batch.
     * @param perkIds List of perk ids to buy.
     * @param amounts List of amounts to buy the ascension perks.
     */
    function buyAscensionPerks(uint256[] calldata perkIds, uint256[] calldata amounts) external returns();

    /**
     * @dev Function to perform an ascension.
     */
    function ascend() external receive returns();

    /**
     * @dev Function to tip the contract owner. Thanks for the support!
     */
    function tip() external payable returns();

    // Public functions

    /**
     * @dev Function to get the player lines per second, computed using the player's data.
     * @param player The address of the player.
     */
    function getPlayerLinesPerSecond(address player) public view returns (BigNumber memory);

    /**
     * @dev Function to get the player lines, computed using the player's data.
     * @param player The address of the player.
     */
    function getPlayerLines(address player) public view returns (BigNumber memory);

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
    function _levelUpPolygon(uint256 polygonId, uint256 amount) internal returns();
    
    /**
     * @dev Internal function to buy an upgrade.
     * @param upgradeId The id of the upgrade to buy.
     * @param amount The amount to buy the upgrade.
     * 
     * Requirements:
     * - The previous upgrade (upgradeId - 1) must be at least at level 1 (except for upgradeId = 0)
     * - The player must have enough lines to buy the upgrade.
     */
    function _buyUpgrade(uint256 upgradeId, uint256 amount) internal returns();
    
    /**
     * @dev Internal function to buy an ascension perk.
     * @param perkId The id of the ascension perk to buy.
     * @param amount The amount to buy the ascension perk.
     * 
     * Requirements:
     * - The previous ascension perk (perkId - 1) must be at least at level 1 (except for perkId = 0)
     * - The player must have enough circles to buy the ascension perk.
     */
    function _buyAscensionPerk(uint256 perkId, uint256 amount) internal returns();

    /**
     * @dev Internal function to update the player data, including the number of lines and the timestamp of the last update, as well as the total number of lines of all time. Should be called before any action that affects the player's data.
     */
    function _updatePlayerData() internal returns();
}
