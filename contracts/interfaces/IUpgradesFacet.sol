// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import { BigNumber } from "../libraries/BigNumber.sol";

/**
 * @dev Error thrown when the arguments are invalid.
 */
error InvalidArguments();

/**
 * @dev Error thrown when buying an upgrade is not allowed.
 * @param upgradeId The ID of the upgrade.
 * @param amountOfLevels The number of levels requested.
 */
error UpgradeNotAllowed(uint256 upgradeId, uint256 amountOfLevels);

/**
 * @dev Error thrown when there are not enough lines to buy an upgrade.
 * @param upgradeId The ID of the upgrade.
 * @param amountOfLevels The amount of levels needed to buy the upgrade.
 */
error NotEnoughLinesToBuyUpgrade(uint256 upgradeId, uint256 amountOfLevels);

interface IUpgradesFacet {
    /**
     * @dev Emitted when an upgrade is bought.
     * @param player The address of the player.
     * @param upgradeId The ID of the upgrade.
     * @param amountOfLevels The number of levels gained.
     */
    event UpgradeBought(
        address indexed player,
        uint256 upgradeId,
        uint256 amountOfLevels
    );

    /**
     * @dev Function to buy upgrades in batch.
     * @param upgradeIds List of upgrade ids to buy.
     * @param amounts List of amounts to buy the upgrades.
     */
    function buyUpgrades(
        uint256[] calldata upgradeIds,
        uint256[] calldata amounts
    ) external;

    /**
     * @dev Get the cost of leveling up an upgrade.
     * @param upgradeId The ID of the upgrade.
     * @param upgradeCurrentLevel The current level of the upgrade.
     * @param amount The amount of levels to level up the upgrade.
     */
    function getUpgradeLevelUpCost(
        uint256 upgradeId,
        uint256 upgradeCurrentLevel,
        uint256 amount
    ) external view returns (BigNumber memory cost);
}
