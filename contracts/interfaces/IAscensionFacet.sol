// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/**
 * @dev Error thrown when the arguments are invalid.
 */
error InvalidArguments();

/**
 * @dev Error thrown when an ascension perk is not allowed.
 * @param perkId The ID of the perk.
 * @param amountOfLevels The amount of levels needed to buy the perk.
 */
error AscensionPerkNotAllowed(uint256 perkId, uint256 amountOfLevels);

/**
 * @dev Error thrown when there are not enough circles to buy a perk.
 * @param perkId The ID of the perk.
 * @param amountOfLevels The amount of levels needed to buy the perk.
 */
error NotEnoughCirclesToBuyPerk(uint256 perkId, uint256 amountOfLevels);

/**
 * @dev Error thrown when ascension is not allowed.
 */
error AscensionNotAllowed();

interface IAscensionFacet {
    /**
     * @dev Emitted when an ascension perk is bought.
     * @param player The address of the player.
     * @param perkId The ID of the perk.
     * @param amountOfLevels The number of levels gained.
     */
    event AscensionPerkBought(
        address indexed player,
        uint256 perkId,
        uint256 amountOfLevels
    );

    /**
     * @dev Emitted when a player ascends.
     * @param player The address of the player.
     */
    event Ascended(address indexed player);

    /**
     * @dev Function to buy ascension perks in batch.
     * @param perkIds List of perk ids to buy.
     * @param amounts List of amounts to buy the ascension perks.
     */
    function buyAscensionPerks(
        uint256[] calldata perkIds,
        uint256[] calldata amounts
    ) external;

    /**
     * @dev Function to perform an ascension.
     */
    function ascend() external;
}
