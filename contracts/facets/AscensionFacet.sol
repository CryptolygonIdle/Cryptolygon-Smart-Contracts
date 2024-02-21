// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {AppStorage, PlayerDataV1} from "../libraries/AppStorage.sol";
import "../libraries/LibCryptolygonUtils.sol";

import "../interfaces/IAscensionFacet.sol";

contract AscensionFacet is IAscensionFacet {
    using LibCryptolygonUtils for *;
    using BigNumbers for *;

    AppStorage internal s;

    function buyAscensionPerks(
        uint256[] calldata perkIds,
        uint256[] calldata amounts
    ) external {
        if (perkIds.length != amounts.length || perkIds.length == 0) {
            revert InvalidArguments();
        }
        LibCryptolygonUtils._updatePlayerData(s);

        for (uint256 i = 0; i < perkIds.length; i++) {
            uint256 perkId = perkIds[i];
            uint256 amount = amounts[i];

            _buyAscensionPerk(perkId, amount);
        }
    }

    function ascend() external {
        LibCryptolygonUtils._updatePlayerData(s);

        PlayerDataV1 memory playerData = s.playersData[msg.sender];

        // Reset the player's data
        delete s.playersData[msg.sender].levelOfPolygons;
        delete s.playersData[msg.sender].levelOfUpgrades;
        delete s.playersData[msg.sender].levelOfAscensionPerks;

        s.playersData[msg.sender].currentLines = BigNumbers.init(0, false);
        s.playersData[msg.sender].totalLinesThisAscension = BigNumbers.init(
            0,
            false
        );
        s.playersData[msg.sender].totalLinesPreviousAscensions = playerData
            .totalLinesPreviousAscensions
            .add(playerData.totalLinesThisAscension);
        s.playersData[msg.sender].numberOfAscensions =
            playerData.numberOfAscensions +
            1;

        // Emit the Ascended event
        emit Ascended(msg.sender);

        // Compute the number of circles to give to the player
        // Log2(totalLinesPreviousAscensions + totalLinesThisAscension) - Log2(totalLinesPreviousAscensions)
        uint256 circlesToGive = BigNumbers.log2(
            playerData.totalLinesPreviousAscensions.add(
                playerData.totalLinesThisAscension
            )
        ) - (BigNumbers.log2(playerData.totalLinesPreviousAscensions));

        // Mint and give the player the circles
        s.CIRCLE.mint(msg.sender, circlesToGive * 10 ** 18);
    }

    /**
     * @dev Internal function to buy an ascension perk.
     * @param perkId The id of the ascension perk to buy.
     * @param amount The amount to buy the ascension perk.
     *
     * Requirements:
     * - The previous ascension perk (perkId - 1) must be at least at level 1 (except for perkId = 0)
     * - The player must have enough circles to buy the ascension perk.
     */
    function _buyAscensionPerk(uint256 perkId, uint256 amount) internal {
        // Check if the ascension perk can be bought
        if (amount == 0 || s.ascensionPerksProperties.length <= perkId) {
            revert InvalidArguments();
        }

        PlayerDataV1 memory playerData = s.playersData[msg.sender];

        // Check if the player has unlocked the previous ascension perk
        if (perkId > 1 && playerData.levelOfAscensionPerks[perkId - 1] == 0) {
            revert AscensionPerkNotAllowed(perkId, amount);
        }

        // Compute the cost of buying the ascension perk
        uint256 cost = perkId ** perkId *
            (playerData.levelOfAscensionPerks[perkId] + 1) *
            amount;

        // Check if the player has enough circles to buy the ascension perk
        if (s.CIRCLE.balanceOf(msg.sender) < cost) {
            revert NotEnoughCirclesToBuyPerk(perkId, amount);
        }

        // Consume the circles
        s.CIRCLE.transferFrom(msg.sender, address(this), cost);

        // Buy the ascension perk
        s.playersData[msg.sender].levelOfAscensionPerks[perkId] =
            playerData.levelOfAscensionPerks[perkId] +
            (amount);

        // Emit the AscensionPerkBought event
        emit AscensionPerkBought(msg.sender, perkId, amount);
    }
}
