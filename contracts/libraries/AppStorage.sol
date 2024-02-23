// SPDX-License-Identifier: MIT
pragma solidity 0.8.20;

import "./BigNumber.sol";

import "../interfaces/ICircle.sol";

/**
 * @dev PlayerDataV1 struct to store player data.
 *
 * @param levelOfPolygons: Array of the level of polygons owned by the player. 0 index is the total level of all polygons.
 * @param levelOfAscensionPerks: Array of the level of ascension perks for the player.
 * @param levelOfUpgrades: Array of the polygons multiplier upgrades for the player.
 * @param totalPolygonsLevel: Total level of all polygons owned by the player.
 * @param timestampLastUpdate: Timestamp of the last update for the player.
 * @param currentLines: BigNumber of the lines at the last update for the player.
 * @param totalLinesThisAscension: Total number of lines for the player this ascension.
 * @param totalLinesPreviousAscensions: Total number of lines for the player in previous ascensions.
 * @param numberOfAscensions: Number of ascensions performed by the players.
 */
struct PlayerDataV1 {
    uint256[] levelOfPolygons;
    uint256[] levelOfAscensionPerks;
    uint256[] levelOfUpgrades;
    uint256 totalPolygonsLevel;
    uint256 timestampLastUpdate;
    BigNumber currentLines;
    BigNumber totalLinesThisAscension;
    BigNumber totalLinesPreviousAscensions;
    uint256 numberOfAscensions;
}

/**
 * @dev PolygonDataV1 struct to store polygon data.
 *
 * @param baseCost: Base cost of the polygon.
 * @param baseLinesPerSecond: Base lines per second of the polygon.
 */
struct PolygonPropertiesV1 {
    uint256 baseCost;
    uint256 baseLinesPerSecond;
}


/**
 * @dev UpgradePropertiesV1 struct to store upgrade data.
 *
 * @param baseCost: Base cost of the upgrade.
 * @param baseEffect: Base effect of the upgrade.
 */
struct UpgradePropertiesV1 {
    uint256 baseCost;
    uint256 baseEffect;
}

/**
 * @dev AscensionPerkPropertiesV1 struct to store ascension perk data.
 *
 * @param baseCost: Base cost of the ascension perk.
 * @param baseEffect: Base effect of the ascension perk.
 */
struct AscensionPerkPropertiesV1 {
    uint256 baseCost;
    uint256 baseEffect;
}

struct AppStorage {
    mapping(address => PlayerDataV1) playersData;
    PolygonPropertiesV1[] polygonsProperties;
    UpgradePropertiesV1[] upgradesProperties;
    AscensionPerkPropertiesV1[] ascensionPerksProperties;
    ICircle CIRCLE;
}
