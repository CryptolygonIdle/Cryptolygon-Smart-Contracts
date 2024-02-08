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
        uint256[] levelOfUpgrades;
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

    // External functions

    /**
     * @dev Function to level up the polygons in batch.
     * @param polygonIds List of polygon ids to level up.
     * @param amounts List of amounts to level up the polygons.
     */
    function levelUpPolygons(uint256[] calldata polygonIds, uint256[] calldata amounts) external;

    /**
     * @dev Function to buy upgrades in batch.
     * @param upgradeIds List of upgrade ids to buy.
     * @param amounts List of amounts to buy the upgrades.
     */
    function buyUpgrades(uint256[] calldata upgradeIds, uint256[] calldata amounts) external;

    /**
     * @dev Function to buy ascension perks in batch.
     * @param perkIds List of perk ids to buy.
     * @param amounts List of amounts to buy the ascension perks.
     */
    function buyAscensionPerks(uint256[] calldata perkIds, uint256[] calldata amounts) external;

    /**
     * @dev Function to perform an ascension.
     */
    function ascend() external;

    /**
     * @dev Function to tip the contract owner. Thanks for the support!
     */
    function tip() external payable;
}
