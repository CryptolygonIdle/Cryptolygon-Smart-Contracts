// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import { BigNumber } from "../libraries/BigNumber.sol";

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

interface IPolygonsFacet {
    /**
     * @dev Emitted when a polygon is leveled up.
     * @param player The address of the player.
     * @param polygonId The ID of the polygon.
     * @param amountOfLevels The number of levels gained.
     */
    event PolygonLeveledUp(
        address indexed player,
        uint256 polygonId,
        uint256 amountOfLevels
    );

    /**
     * @dev Level up the polygons of the player.
     * @param polygonIds The IDs of the polygons to level up.
     * @param amounts The number of levels to level up the polygons.
     *
     * Requirements:
     * - The length of polygonIds and amounts must be the same.
     * - The length of polygonIds and amounts must be greater than 0.
     **/
    function levelUpPolygons(
        uint256[] calldata polygonIds,
        uint256[] calldata amounts
    ) external;

    /**
     * @dev Get the cost of leveling up a polygon.
     * @param polygonId The ID of the polygon.
     * @param polygonCurrentLevel The current level of the polygon.
     * @param amount The amount of levels to level up the polygon.
     */
    function getPolygonLevelUpCost(
        uint256 polygonId,
        uint256 polygonCurrentLevel,
        uint256 amount
    ) external view returns (BigNumber memory cost);

}
