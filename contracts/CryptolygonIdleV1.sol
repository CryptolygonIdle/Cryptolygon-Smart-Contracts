// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "./interfaces/ICryptolygonIdleV1.sol";

import "@openzeppelin/contracts-upgradeable/utils/PausableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";

/// @custom:security-contact
contract CryptolygonIdleV1 is ICryptolygonIdleV1, Initializable, PausableUpgradeable, OwnableUpgradeable, UUPSUpgradeable {
    using BigNumber for BigNumber;

    mapping (address => PlayerDataV1) public playersData;

    address constant public CIRCLE_ADDRESS = 0x

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() {
        _disableInitializers();
    }

    function initialize(address initialOwner) initializer public {
        __Pausable_init();
        __Ownable_init(initialOwner);
        __UUPSUpgradeable_init();
    }

    function pause() public onlyOwner {
        _pause();
    }

    function unpause() public onlyOwner {
        _unpause();
    }

    function _authorizeUpgrade(address newImplementation)
        internal
        onlyOwner
        override
    {}
}