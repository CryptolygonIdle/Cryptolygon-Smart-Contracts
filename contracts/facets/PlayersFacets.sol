// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {AppStorage} from "../libraries/AppStorage.sol";
import "../libraries/BigNumber.sol";

import "../interfaces/IPlayersFacet.sol";

contract PlayersFacet is IPlayersFacet {
    using BigNumbers for *;

    AppStorage internal s;

    /**
     * @dev Emitted when player data is updated.
     * @param player The address of the player.
     * @param lines The number of lines.
     * @param totalLines The total number of lines.
     */
    event PlayerDataUpdated(
        address indexed player,
        BigNumber lines,
        BigNumber totalLines
    );

    function startGame() external {
        if (s.playersData[msg.sender].timestampLastUpdate != 0) {
            revert GameAlreadyStarted();
        }
        s.playersData[msg.sender].timestampLastUpdate = block.timestamp;

        // Set the level of the total polygons and the first polygon to 1
        s.playersData[msg.sender].levelOfPolygons.push(1);
        s.playersData[msg.sender].totalPolygonsLevel = 1;
    }

    /**
     * @dev Updates the player's data.
     * @param player The address of the player.
     */
    function updatePlayerData(address player) public {
        PlayerDataV1 memory playerData = s.playersData[player];
        s.playersData[player].timestampLastUpdate = block.timestamp;

        // Compute the player's lines per second
        BigNumber memory linesPerSecond = BigNumbers.init(0, false);

        for (uint256 i = 1; i < playerData.levelOfPolygons.length - 1; i++) {
            uint256 basePolygonLinesPerSecond = s
                .polygonsProperties[i]
                .baseLinesPerSecond;

            uint256 polygonLevel = playerData.levelOfPolygons[i];
            uint256 totalPolygonLevel = playerData.totalPolygonsLevel;
            uint256 polygonLevelMultiplier = (1 + 2 * (polygonLevel / 50)) *
                (1 + 5 * (totalPolygonLevel / 500));

            uint256 normalUpgradesMultiplier = 1 +
                playerData.levelOfUpgrades[0];

            uint256 ascensionUpgradesMultiplier = 1 +
                playerData.levelOfAscensionPerks[0] *
                (1 + playerData.levelOfUpgrades[3]);

            BigNumber memory polygonLinesPerSecond = BigNumbers
                .init(basePolygonLinesPerSecond, false)
                .mul(BigNumbers.init(polygonLevel, false))
                .mul(BigNumbers.init(polygonLevelMultiplier, false))
                .mul(BigNumbers.init(normalUpgradesMultiplier, false))
                .mul(BigNumbers.init(ascensionUpgradesMultiplier, false));

            linesPerSecond = linesPerSecond.add(polygonLinesPerSecond);
        }

        // Compute the player's lines
        uint256 timePassed = block.timestamp - playerData.timestampLastUpdate;
        BigNumber memory newLinesSinceLastUpdate = linesPerSecond.mul(
            BigNumbers.init(timePassed, false)
        );

        // Update the player's data
        s.playersData[player].currentLines = playerData.currentLines.add(
            newLinesSinceLastUpdate
        );
        s.playersData[player].totalLinesThisAscension = playerData
            .totalLinesThisAscension
            .add(newLinesSinceLastUpdate);

        emit PlayerDataUpdated(
            player,
            playerData.currentLines.add(newLinesSinceLastUpdate),
            playerData.totalLinesThisAscension
        );
    }

    /**
     * @dev Returns the player's data.
     * @param player The address of the player.
     * @return The player's data.
     */
    function getPlayerData(
        address player
    ) public view returns (PlayerDataV1 memory) {
        return s.playersData[player];
    }
}
