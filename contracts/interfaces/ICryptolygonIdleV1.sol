// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "../libraries/BigNumber.sol";

/**
 * @title ICryptolygonIdleV1
 * @dev Interface for the Cryptolygon Idle contract.
 */
interface ICryptolygonIdleV1 {
    
    /**
     * @dev PlayerDataV1 struct to store player data.
     * 
     * levelOfPolygons: Array of the level of polygons owned by the player.
     * levelOfAscensionPerks: Array of the level of ascension perks for the player.
     * polygonsMultiplierUpgrades: Array of the polygons multiplier upgrades for the player.
     * timestampLastUpdate: Timestamp of the last update for the player.
     * linesLastUpdate: BigNumber of the lines at the last update for the player.
     * totalLines: Total number of lines for the player.
     * numberOfAscensions: Number of ascensions performed by the players.
     */
    struct PlayerDataV1 {
        uint256[] levelOfPolygons;
        uint256[] levelOfAscensionPerks;
        uint256[] polygonsMultiplierUpgrades;
        uint256 timestampLastUpdate;
        BigNumber linesLastUpdate;
        uint256 totalLines;
        uint256 numberOfAscensions;
    }

    // External functions

    /**
     * @dev Function to level up the polygons in batch.
     * @param polygonIds List of polygon ids to level up.
     * @param amounts List of amounts to level up the polygons.
     */
    function levelUpPolygons(uint256[] memory polygonIds, uint256[] memory amounts) external returns();

    /**
     * @dev Function to buy upgrades in batch.
     * @param upgradeIds List of upgrade ids to buy.
     * @param amounts List of amounts to buy the upgrades.
     */
    function buyUpgrades(uint256[] memory upgradeIds, uint256[] memory amounts) external returns();

    /**
     * @dev Function to buy ascension perks in batch.
     * @param perkIds List of perk ids to buy.
     * @param amounts List of amounts to buy the ascension perks.
     */
    function buyAscensionPerks(uint256[] memory perkIds, uint256[] memory amounts) external returns();

    /**
     * @dev Function to perform an ascension.
     */
    function ascend() external returns();

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
     */
    function _levelUpPolygon(uint256 polygonId, uint256 amount) internal returns();
    
    /**
     * @dev Internal function to buy an upgrade.
     * @param upgradeId The id of the upgrade to buy.
     * @param amount The amount to buy the upgrade.
     */
    function _buyUpgrade(uint256 upgradeId, uint256 amount) internal returns();
    
    /**
     * @dev Internal function to buy an ascension perk.
     * @param perkId The id of the ascension perk to buy.
     * @param amount The amount to buy the ascension perk.
     */
    function _buyAscensionPerk(uint256 perkId, uint256 amount) internal returns();

    /**
     * @dev Internal function to update the player data, including the number of lines and the timestamp of the last update, as well as the total number of lines of all time.
     */
    function _updatePlayerData() internal returns();
}
