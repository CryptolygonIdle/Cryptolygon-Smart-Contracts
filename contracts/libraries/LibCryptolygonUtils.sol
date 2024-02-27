// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {AppStorage, PlayerDataV1} from "./AppStorage.sol";
import {LibDiamond} from "./LibDiamond.sol";

import "./BigNumber.sol";

library LibCryptolygonUtils {
    using BigNumbers for *;

    /**
     * @dev Emitted when player data is updated.
     * @param player The address of the player.
     */
    event PlayerDataUpdated(address indexed player);

    function _updatePlayerData(address player) internal {
        bytes4 updateFunctionSig = bytes4(
            keccak256(bytes("updatePlayerData(address)"))
        );
        LibDiamond.DiamondStorage storage ds;
        bytes32 position = LibDiamond.DIAMOND_STORAGE_POSITION;
        // get diamond storage
        assembly {
            ds.slot := position
        }

        address updateFunctionFacet = ds
            .facetAddressAndSelectorPosition[updateFunctionSig]
            .facetAddress;

        // Encode the function call data
        bytes memory encodedFunctionCall = abi.encodeWithSelector(
            updateFunctionSig,
            player
        );

        (bool success, ) = updateFunctionFacet.delegatecall(
            encodedFunctionCall
        );
        if (!success) {
            revert();
        }

        emit PlayerDataUpdated(msg.sender);
    }
}
