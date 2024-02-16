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

struct AppStorage {
    mapping(address => PlayerDataV1)  playersData;
    ICircle CIRCLE;
}
