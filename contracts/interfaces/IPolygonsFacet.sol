// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

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
    event PolygonLeveledUp(address indexed player, uint256 polygonId, uint256 amountOfLevels);

    function levelUpPolygons(uint256[] calldata polygonIds, uint256[] calldata amounts) external;
}