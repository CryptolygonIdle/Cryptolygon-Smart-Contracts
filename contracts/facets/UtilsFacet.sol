// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {
    AppStorage, 
    PolygonPropertiesV1, 
    UpgradePropertiesV1,
    AscensionPerkPropertiesV1
} from "../libraries/AppStorage.sol";

contract UtilsFacet {

    AppStorage internal s;

    function getPolygonsProperties() external view returns (PolygonPropertiesV1[] memory) {
        return s.polygonsProperties;
    }

    function getUpgradesProperties() external view returns (UpgradePropertiesV1[] memory) {
        return s.upgradesProperties;
    }

    function getAscensionPerksProperties() external view returns (AscensionPerkPropertiesV1[] memory) {
        return s.ascensionPerksProperties;
    }

    function getCircleAddress() external view returns (address) {
        return address(s.CIRCLE);
    }
}