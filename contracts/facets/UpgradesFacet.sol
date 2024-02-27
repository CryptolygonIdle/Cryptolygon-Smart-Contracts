// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {AppStorage, PlayerDataV1} from "../libraries/AppStorage.sol";
import "../libraries/LibCryptolygonUtils.sol";

import "../interfaces/IUpgradesFacet.sol";

contract UpgradesFacet is IUpgradesFacet {
    using LibCryptolygonUtils for *;
    using BigNumbers for *;

    AppStorage internal s;

    function buyUpgrades(
        uint256[] calldata upgradeIds,
        uint256[] calldata amounts
    ) external {
        if (upgradeIds.length != amounts.length || upgradeIds.length == 0) {
            revert InvalidArguments();
        }
        LibCryptolygonUtils._updatePlayerData(msg.sender);

        for (uint256 i = 0; i < upgradeIds.length; i++) {
            uint256 upgradeId = upgradeIds[i];
            uint256 amount = amounts[i];

            _buyUpgrade(upgradeId, amount);
        }
    }

    /**
     * @dev Internal function to buy an upgrade.
     * @param upgradeId The id of the upgrade to buy.
     * @param amount The amount to buy the upgrade.
     *
     * Requirements:
     * - The previous upgrade (upgradeId - 1) must be at least at level 1 (except for upgradeId = 0)
     * - The player must have enough lines to buy the upgrade.
     */
    function _buyUpgrade(uint256 upgradeId, uint256 amount) internal {
        // Check if the upgrade can be bought
        if (amount == 0 || s.upgradesProperties.length <= upgradeId) {
            revert UpgradeNotAllowed(upgradeId, amount);
        }

        PlayerDataV1 memory playerData = s.playersData[msg.sender];

        // Compute the cost of buying the upgrade
        // Cost = upgradeBaseCost * 2**upgradeCurrentLevel * (2**amountToBuy - 1)
        // 2 is the cost growth coefficient
        BigNumber memory cost = BigNumbers.init(s.upgradesProperties[upgradeId].baseCost, false)
            .mul(BigNumbers.init(2, false).pow(playerData.levelOfUpgrades[upgradeId]))
            .mul(BigNumbers.init(2, false).pow(amount).sub(BigNumbers.init(1, false)));

        // Check if the player has enough lines to buy the upgrade
        if (playerData.currentLines.lt(cost)) {
            revert NotEnoughLinesToBuyUpgrade(upgradeId, amount);
        }

        // Consume the lines
        s.playersData[msg.sender].currentLines = playerData
            .currentLines
            .sub(cost);

        // Buy the upgrade
        s.playersData[msg.sender].levelOfUpgrades[upgradeId] =
            playerData.levelOfUpgrades[upgradeId] +
            (amount);

        // Emit the UpgradeBought event
        emit UpgradeBought(msg.sender, upgradeId, amount);
    }
}
