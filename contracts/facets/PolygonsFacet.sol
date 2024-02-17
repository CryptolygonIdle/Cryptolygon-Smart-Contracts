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
        LibCryptolygonUtils._updatePlayerData(s);

        for (uint256 i = 0; i < polygonIds.length; i++) {
            uint256 polygonId = polygonIds[i];
            uint256 amount = amounts[i];

            _levelUpPolygon(polygonId, amount);
        }
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
        if (polygonId == 0 || amount == 0) {
            revert PolygonLevelUpNotAllowed(polygonId, amount);
        }

        PlayerDataV1 memory playerData = s.playersData[msg.sender];

        // Check if the player has unlocked the previous polygon
        if (polygonId > 1 && playerData.levelOfPolygons[polygonId - 1] == 0) {
            revert PolygonLevelUpNotAllowed(polygonId, amount);
        }

        // Compute the cost of leveling up the polygon
        BigNumber memory cost = BigNumbers.init(0, false);

        for (uint256 i = 0; i < amount; i++) {
            cost = cost.add(
                BigNumbers.init(polygonId ** polygonId, false).mul(
                    BigNumbers.init(
                        playerData.levelOfPolygons[polygonId],
                        false
                    )
                )
            );
        }

        // Check if the player has enough lines to level up the polygon
        if (playerData.linesLastUpdate.lt(cost)) {
            revert NotEnoughLinesToLevelUp(polygonId, amount);
        }

        // Consume the lines
        s.playersData[msg.sender].linesLastUpdate = playerData
            .linesLastUpdate
            .sub(cost);

        // Level up the polygon
        s.playersData[msg.sender].levelOfPolygons[polygonId] =
            playerData.levelOfPolygons[polygonId] +
            (amount);

        // Level up the all polygons level
        s.playersData[msg.sender].levelOfPolygons[0] =
            playerData.levelOfPolygons[0] +
            (amount);

        // Emit the PolygonLeveledUp event
        emit PolygonLeveledUp(msg.sender, polygonId, amount);
    }
}
