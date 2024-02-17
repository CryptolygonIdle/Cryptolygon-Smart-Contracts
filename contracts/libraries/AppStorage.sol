// SPDX-License-Identifier: MIT
pragma solidity 0.8.20;

import "./BigNumber.sol";

import "../interfaces/ICircle.sol";

/**
 * @dev PlayerDataV1 struct to store player data.
 *
 * @param levelOfPolygons: Array of the level of polygons owned by the player. 0 index is the total level of all polygons.
 * @param levelOfAscensionPerks: Array of the level of ascension perks for the player.
 * @param polygonsMultiplierUpgrades: Array of the polygons multiplier upgrades for the player.
 * @param timestampLastUpdate: Timestamp of the last update for the player.
 * @param linesLastUpdate: BigNumber of the lines at the last update for the player.
 * @param totalLinesThisAscension: Total number of lines for the player this ascension.
 * @param totalLinesPreviousAscensions: Total number of lines for the player in previous ascensions.
 * @param numberOfAscensions: Number of ascensions performed by the players.
 */
struct PlayerDataV1 {
    uint256[] levelOfPolygons;
    uint256[] levelOfAscensionPerks;
    uint256[] levelOfUpgrades;
    uint256 timestampLastUpdate;
    BigNumber linesLastUpdate;
    BigNumber totalLinesThisAscension;
    BigNumber totalLinesPreviousAscensions;
    uint256 numberOfAscensions;
}

/**
 * @dev PolygonDataV1 struct to store polygon data.
 *
 * @param baseCost: Base cost of the polygon.
 * @param baseLinesPerSecond: Base lines per second of the polygon.
 * @param costCoefficient2Decimals: Cost coefficient of the polygon written with 2 decimals. Cost is multiplied by this value for each level.
 */
struct PolygonPropertiesV1 {
    uint256 baseCost;
    uint256 baseLinesPerSecond;
    uint256 costCoefficient2Decimals;
}


/**
 * @dev UpgradePropertiesV1 struct to store upgrade data.
 *
 * @param baseCost: Base cost of the upgrade.
 * @param baseEffect: Base effect of the upgrade.
 * @param costCoefficient3Decimals: Cost coefficient of the upgrade. Cost is multiplied by this value for each level.
 */
struct UpgradePropertiesV1 {
    uint256 baseCost;
    uint256 baseEffect;
    uint256 costCoefficient3Decimals;
}

struct AscensionPerkPropertiesV1 {
    uint256 baseCost;
    uint256 baseEffect;
    uint256 costCoefficient3Decimals;
}

struct AppStorage {
    mapping(address => PlayerDataV1) playersData;
    PolygonPropertiesV1[] polygonsProperties;
    UpgradePropertiesV1[] upgradesProperties;
    ICircle CIRCLE;
}
