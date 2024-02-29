// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {AppStorage, PlayerDataV1} from "../libraries/AppStorage.sol";
import "../libraries/LibCryptolygonUtils.sol";

import "../interfaces/IPolygonsFacet.sol";

contract PolygonsFacet is IPolygonsFacet {
    using LibCryptolygonUtils for *;
    using BigNumbers for *;

    AppStorage internal s;

    function levelUpPolygons(
        uint256[] calldata polygonIds,
        uint256[] calldata amounts
    ) external {
        if (polygonIds.length != amounts.length || polygonIds.length == 0) {
            revert InvalidArguments();
        }
        LibCryptolygonUtils._updatePlayerData(msg.sender);

        for (uint256 i = 0; i < polygonIds.length; i++) {
            uint256 polygonId = polygonIds[i];
            uint256 amount = amounts[i];

            _levelUpPolygon(polygonId, amount);
        }
    }

    function getPolygonLevelUpCost(
        uint256 polygonId,
        uint256 polygonCurrentLevel,
        uint256 amount
    ) public view returns (BigNumber memory cost) {
        // Compute the cost of leveling up the polygon
        // Cost = polygonBaseCost * 2**polygonCurrentLevel * (2**amountToBuy - 1)
        // 2 is the cost growth coefficient
        cost = BigNumbers
            .init(s.polygonsProperties[polygonId].baseCost, false)
            .mul(
                BigNumbers.init(2, false).pow(
                    polygonCurrentLevel
                )
            )
            .mul(
                BigNumbers.init(2, false).pow(amount).sub(
                    BigNumbers.init(1, false)
                )
            );
    }

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
        // Check if the polygon can be leveled up
        if (amount == 0 || s.polygonsProperties.length <= polygonId) {
            revert InvalidArguments();
        }

        PlayerDataV1 memory playerData = s.playersData[msg.sender];

        // Check if the player has unlocked the previous polygon
        if (
            polygonId > playerData.levelOfPolygons.length ||
            (polygonId > 1 && playerData.levelOfPolygons[polygonId - 1] == 0)
        ) {
            revert PolygonLevelUpNotAllowed(polygonId, amount);
        }

        // Add the polygon to the player's data if it doesn't exist
        if (polygonId == playerData.levelOfPolygons.length) {
            s.playersData[msg.sender].levelOfPolygons.push(0);
        }

        BigNumber memory cost = getPolygonLevelUpCost(
            polygonId,
            s.playersData[msg.sender].levelOfPolygons[polygonId],
            amount
        );

        if (playerData.levelOfUpgrades[1] > 0) {
            cost = BigNumbers.div2multiple(cost, playerData.levelOfUpgrades[1]);
        }

        // Check if the player has enough lines to level up the polygon
        if (playerData.currentLines.lt(cost)) {
            revert NotEnoughLinesToLevelUp(polygonId, amount);
        }

        // Consume the lines
        s.playersData[msg.sender].currentLines = playerData.currentLines.sub(
            cost
        );

        // Level up the polygon
        s.playersData[msg.sender].levelOfPolygons[polygonId] += (amount);

        // Level up the total polygons level
        s.playersData[msg.sender].totalPolygonsLevel += (amount);

        // Emit the PolygonLeveledUp event
        emit PolygonLeveledUp(msg.sender, polygonId, amount);
    }
}
