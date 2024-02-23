// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/******************************************************************************\
* Author: Nick Mudge <nick@perfectabstractions.com> (https://twitter.com/mudgen)
* EIP-2535 Diamonds: https://eips.ethereum.org/EIPS/eip-2535
*
* Implementation of a diamond.
/******************************************************************************/

import {LibDiamond} from "../libraries/LibDiamond.sol";
import {IDiamondLoupe} from "../interfaces/IDiamondLoupe.sol";
import {IDiamondCut} from "../interfaces/IDiamondCut.sol";
import {IERC173} from "../interfaces/IERC173.sol";
import {IERC165} from "../interfaces/IERC165.sol";

import { ICircle } from "../interfaces/ICircle.sol";

import {AppStorage, PolygonPropertiesV1, UpgradePropertiesV1, AscensionPerkPropertiesV1} from "../libraries/AppStorage.sol";

// It is expected that this contract is customized if you want to deploy your diamond
// with data from a deployment script. Use the init function to initialize state variables
// of your diamond. Add parameters to the init funciton if you need to.

// Adding parameters to the `init` or other functions you add here can make a single deployed
// DiamondInit contract reusable accross upgrades, and can be used for multiple diamonds.

contract DiamondInit {
    AppStorage internal s;

    // You can add parameters to this function in order to pass in
    // data to set your own state variables
    function init(address circle) external {
        // adding ERC165 data
        LibDiamond.DiamondStorage storage ds = LibDiamond.diamondStorage();
        ds.supportedInterfaces[type(IERC165).interfaceId] = true;
        ds.supportedInterfaces[type(IDiamondCut).interfaceId] = true;
        ds.supportedInterfaces[type(IDiamondLoupe).interfaceId] = true;
        ds.supportedInterfaces[type(IERC173).interfaceId] = true;

        // add your own state variables
        // EIP-2535 specifies that the `diamondCut` function takes two optional
        // arguments: address _init and bytes calldata _calldata
        // These arguments are used to execute an arbitrary function using delegatecall
        // in order to set state variables in the diamond during deployment or an upgrade
        // More info here: https://eips.ethereum.org/EIPS/eip-2535#diamond-interface

        setupPolygonProperties();
        setupUpgradesProperties();
        setupAscensionPerksProperties();

        s.CIRCLE = ICircle(circle);
    }

    function setupPolygonProperties() internal {
        s.polygonsProperties.push(PolygonPropertiesV1({
            baseCost: 2**256 - 1,
            baseLinesPerSecond: 0
        }));
        s.polygonsProperties.push(PolygonPropertiesV1({
            baseCost: 1,
            baseLinesPerSecond: 2
        }));
        s.polygonsProperties.push(PolygonPropertiesV1({
            baseCost: 20,
            baseLinesPerSecond: 5
        }));
        s.polygonsProperties.push(PolygonPropertiesV1({
            baseCost: 400,
            baseLinesPerSecond: 20
        }));
        s.polygonsProperties.push(PolygonPropertiesV1({
            baseCost: 8000,
            baseLinesPerSecond: 50
        }));
        s.polygonsProperties.push(PolygonPropertiesV1({
            baseCost: 160000,
            baseLinesPerSecond: 200
        }));
        s.polygonsProperties.push(PolygonPropertiesV1({
            baseCost: 3200000,
            baseLinesPerSecond: 1000
        }));
        s.polygonsProperties.push(PolygonPropertiesV1({
            baseCost: 64000000,
            baseLinesPerSecond: 5000
        }));


    }

    function setupUpgradesProperties() internal {
        s.upgradesProperties.push(UpgradePropertiesV1({
            baseCost: 1,
            baseEffect: 1
        }));
        s.upgradesProperties.push(UpgradePropertiesV1({
            baseCost: 1,
            baseEffect: 1
        }));
        s.upgradesProperties.push(UpgradePropertiesV1({
            baseCost: 1000,
            baseEffect: 1
        }));
        s.upgradesProperties.push(UpgradePropertiesV1({
            baseCost: 1000,
            baseEffect: 1
        }));
    }

    function setupAscensionPerksProperties() internal {
        s.ascensionPerksProperties.push(AscensionPerkPropertiesV1({
            baseCost: 1,
            baseEffect: 1
        }));
        s.ascensionPerksProperties.push(AscensionPerkPropertiesV1({
            baseCost: 1,
            baseEffect: 1
        }));
        s.ascensionPerksProperties.push(AscensionPerkPropertiesV1({
            baseCost: 10,
            baseEffect: 1
        }));
    }
}
