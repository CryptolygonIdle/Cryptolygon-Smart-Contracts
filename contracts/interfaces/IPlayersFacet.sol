// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import { PlayerDataV1} from "../libraries/AppStorage.sol";

/**
 * @dev Error thrown when the game has already started and the player tries to start it again.
 */
error GameAlreadyStarted();

interface IPlayersFacet {
    /**
     * @dev Emitted when the game is started.
     */
    event GameStarted();

    /**
     * @dev Start the game.
     *
     * Requirements:
     * - The game must not have started yet.
     */
    function startGame() external;

    /**
     * @dev Get the address of the player.
     * @param player The address of the player.
     */
    function updatePlayerData(address player) external;

    /**
     * @dev Get the player's data.
     * @param player The address of the player.
     */
    function getPlayerData(address player) external view returns (PlayerDataV1 memory);

}