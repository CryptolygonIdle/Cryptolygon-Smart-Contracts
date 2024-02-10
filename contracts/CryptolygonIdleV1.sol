// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "./interfaces/ICryptolygonIdleV1.sol";
import "./interfaces/ICircle.sol";

import "@openzeppelin/contracts-upgradeable/utils/PausableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";


/// @custom:security-contact
contract CryptolygonIdleV1 is ICryptolygonIdleV1, Initializable, PausableUpgradeable, OwnableUpgradeable, UUPSUpgradeable {
    using BigNumbers for *;

    mapping(address => PlayerDataV1) public playersData;

    ICircle constant public CIRCLE = ICircle(address(0));

    // Errors

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

    // Admin functions

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

    // Game external functions

    /**
     * @inheritdoc ICryptolygonIdleV1
     */
    function levelUpPolygons(uint256[] calldata polygonIds, uint256[] calldata amounts) external {
        if (polygonIds.length != amounts.length || polygonIds.length == 0) {
            revert InvalidArguments();
        }
        _updatePlayerData();

        for (uint256 i = 0; i < polygonIds.length; i++) {
            uint256 polygonId = polygonIds[i];
            uint256 amount = amounts[i];

            _levelUpPolygon(polygonId, amount);
        }
    }

    /**
     * @inheritdoc ICryptolygonIdleV1
     */
    function buyUpgrades(uint256[] calldata upgradeIds, uint256[] calldata amounts) external {
        if (upgradeIds.length != amounts.length || upgradeIds.length == 0) {
            revert InvalidArguments();
        }
        _updatePlayerData();

        for (uint256 i = 0; i < upgradeIds.length; i++) {
            uint256 upgradeId = upgradeIds[i];
            uint256 amount = amounts[i];

            _buyUpgrade(upgradeId, amount);
        }
    }

    /**
     * @inheritdoc ICryptolygonIdleV1
     */
    function buyAscensionPerks(uint256[] calldata perkIds, uint256[] calldata amounts) external {
        if (perkIds.length != amounts.length || perkIds.length == 0) {
            revert InvalidArguments();
        }
        _updatePlayerData();

        for (uint256 i = 0; i < perkIds.length; i++) {
            uint256 perkId = perkIds[i];
            uint256 amount = amounts[i];

            _buyAscensionPerk(perkId, amount);
        }
    }

    /**
     * @inheritdoc ICryptolygonIdleV1
     */
    function ascend() external {
        _updatePlayerData();

        PlayerDataV1 memory playerData = playersData[msg.sender];

        // Reset the player's data
        uint256[] memory emptyArray1;
        playersData[msg.sender].levelOfPolygons = emptyArray1;

        uint256[] memory emptyArray2;
        playersData[msg.sender].levelOfUpgrades = emptyArray2;

        uint256[] memory emptyArray3;
        playersData[msg.sender].levelOfAscensionPerks = emptyArray3;

        playersData[msg.sender].linesLastUpdate = BigNumbers.init(0, false);
        playersData[msg.sender].totalLinesThisAscension = BigNumbers.init(0, false);
        playersData[msg.sender].totalLinesPreviousAscensions = playerData.totalLinesPreviousAscensions.add(playerData.totalLinesThisAscension);
        playersData[msg.sender].numberOfAscensions = playerData.numberOfAscensions + 1;

        // Emit the Ascended event
        emit Ascended(msg.sender);

        // Compute the number of circles to give to the player
        // Log2(totalLinesPreviousAscensions + totalLinesThisAscension) - Log2(totalLinesPreviousAscensions)
        uint256 circlesToGive = BigNumbers.log2(playerData.totalLinesPreviousAscensions
                                            .add(playerData.totalLinesThisAscension)) 
                                            - (BigNumbers.log2(playerData.totalLinesPreviousAscensions));

        // Mint and give the player the circles
        CIRCLE.mint(msg.sender, circlesToGive * 10**18);

    }

    /**
     * @inheritdoc ICryptolygonIdleV1
     */
    function tip() external payable {
        payable(owner()).transfer(msg.value);
    }

    // Public functions

    /**
     * @dev Function to get the player lines per second, computed using the player's data.
     * @param player The address of the player.
     */
    function getPlayerLinesPerSecond(address player) public view returns (BigNumber memory) {
        PlayerDataV1 memory playerData = playersData[player];

        // Compute the player's lines per second
        BigNumber memory linesPerSecond = BigNumbers.init(0, false);

        for (uint256 i = 1; i < playerData.levelOfPolygons.length - 1; i++) {
            uint256 basePolygonLinesPerSecond = 2**i;

            uint256 polygonLevel = playerData.levelOfPolygons[i];
            uint256 polygonLevelMultiplier = (1 + 2*(polygonLevel/50)) * (1 + 5*(polygonLevel/500));

            uint256 normalUpgradesMultiplier = 1;

            uint256 ascensionUpgradesMultiplier = 1;

            BigNumber memory polygonLinesPerSecond = BigNumbers.init(basePolygonLinesPerSecond, false)
                .mul(BigNumbers.init(polygonLevel, false))
                .mul(BigNumbers.init(polygonLevelMultiplier, false))
                .mul(BigNumbers.init(normalUpgradesMultiplier, false))
                .mul(BigNumbers.init(ascensionUpgradesMultiplier, false));

            linesPerSecond = linesPerSecond.add(polygonLinesPerSecond);
        }

        return linesPerSecond;
    }

    /**
     * @dev Function to get the player lines, computed using the player's data.
     * @param player The address of the player.
     */
    function getPlayerLines(address player) public view returns (BigNumber memory) {
        PlayerDataV1 memory playerData = playersData[player];

        // Compute the player's lines
        uint256 timePassed = block.timestamp - playerData.timestampLastUpdate;
        BigNumber memory newLinesSinceLastUpdate = getPlayerLinesPerSecond(player).mul(BigNumbers.init(timePassed, false));

        return playerData.linesLastUpdate.add(newLinesSinceLastUpdate);
    }

    // Internal functions

    /**
     * @dev Internal function to level up a polygon.
     * @param polygonId The id of the polygon to level up.
     * @param amount The amount to level up the polygon.
     * 
     * Requirements:
     * - The previous polygon (polygonId - 1) must be at least at level 1 (except for polygonId = 1)
     * - The player must have enough lines to level up the polygon.
     */
    function _levelUpPolygon(uint256 polygonId, uint256 amount) internal {
        // Check if the polygon can be leveled up
        if (polygonId == 0 || amount == 0) {
            revert PolygonLevelUpNotAllowed(polygonId, amount);
        }

        PlayerDataV1 memory playerData = playersData[msg.sender];

        // Check if the player has unlocked the previous polygon
        if (polygonId > 1 && playerData.levelOfPolygons[polygonId - 1] == 0) {
            revert PolygonLevelUpNotAllowed(polygonId, amount);
        }

        // Compute the cost of leveling up the polygon
        BigNumber memory cost = BigNumbers.init(0, false);

        for (uint256 i = 0; i < amount; i++) {
            cost = cost.add(BigNumbers.init(polygonId**polygonId, false).mul(BigNumbers.init(playerData.levelOfPolygons[polygonId], false)));
        }

        // Check if the player has enough lines to level up the polygon
        if (playerData.linesLastUpdate.lt(cost)) {
            revert NotEnoughLinesToLevelUp(polygonId, amount);
        }

        // Consume the lines
        playersData[msg.sender].linesLastUpdate = playerData.linesLastUpdate.sub(cost);

        // Level up the polygon
        playersData[msg.sender].levelOfPolygons[polygonId] = playerData.levelOfPolygons[polygonId] + (amount);
        
        // Level up the all polygons level
        playersData[msg.sender].levelOfPolygons[0] = playerData.levelOfPolygons[0] + (amount);

        // Emit the PolygonLeveledUp event
        emit PolygonLeveledUp(msg.sender, polygonId, amount);

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
        if (upgradeId == 0 || amount == 0) {
            revert UpgradeNotAllowed(upgradeId, amount);
        }

        PlayerDataV1 memory playerData = playersData[msg.sender];

        // Check if the player has unlocked the previous upgrade
        if (upgradeId > 1 && playerData.levelOfUpgrades[upgradeId - 1] == 0) {
            revert UpgradeNotAllowed(upgradeId, amount);
        }

        // Compute the cost of buying the upgrade
        BigNumber memory cost = BigNumbers.init(0, false);

        for (uint256 i = 0; i < amount; i++) {
            cost = cost.add(BigNumbers.init(upgradeId**upgradeId, false).mul(BigNumbers.init(playerData.levelOfUpgrades[upgradeId], false)));
        }

        // Check if the player has enough lines to buy the upgrade
        if (playerData.linesLastUpdate.lt(cost)) {
            revert NotEnoughLinesToBuyUpgrade(upgradeId, amount);
        }

        // Consume the lines
        playersData[msg.sender].linesLastUpdate = playerData.linesLastUpdate.sub(cost);

        // Buy the upgrade
        playersData[msg.sender].levelOfUpgrades[upgradeId] = playerData.levelOfUpgrades[upgradeId] + (amount);

        // Emit the UpgradeBought event
        emit UpgradeBought(msg.sender, upgradeId, amount);
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
        if (perkId == 0 || amount == 0) {
            revert AscensionPerkNotAllowed(perkId, amount);
        }

        PlayerDataV1 memory playerData = playersData[msg.sender];

        // Check if the player has unlocked the previous ascension perk
        if (perkId > 1 && playerData.levelOfAscensionPerks[perkId - 1] == 0) {
            revert AscensionPerkNotAllowed(perkId, amount);
        }

        // Compute the cost of buying the ascension perk
        uint256 cost = perkId**perkId * (playerData.levelOfAscensionPerks[perkId] + 1) * amount;

        // Check if the player has enough circles to buy the ascension perk
        if (CIRCLE.balanceOf(msg.sender) < cost) {
            revert NotEnoughCirclesToBuyPerk(perkId, amount);
        }

        // Consume the circles
        CIRCLE.transferFrom(msg.sender, address(this), cost);

        // Buy the ascension perk
        playersData[msg.sender].levelOfAscensionPerks[perkId] = playerData.levelOfAscensionPerks[perkId] + (amount);

        // Emit the AscensionPerkBought event
        emit AscensionPerkBought(msg.sender, perkId, amount);
    }

    /**
     * @dev Internal function to update the player data, including the number of lines and the timestamp of the last update, as well as the total number of lines of all time. Should be called before any action that affects the player's data.
     * NOTE : Not using getPlayerLinesPerSecond and getPlayerLines to avoid gas costs
     */
    function _updatePlayerData() internal {
        PlayerDataV1 memory playerData = playersData[msg.sender];
        playersData[msg.sender].timestampLastUpdate = block.timestamp;

        // Compute the player's lines per second
        BigNumber memory linesPerSecond = BigNumbers.init(0, false);

        for (uint256 i = 1; i < playerData.levelOfPolygons.length - 1; i++) {
            uint256 basePolygonLinesPerSecond = 2**i;

            uint256 polygonLevel = playerData.levelOfPolygons[i];
            uint256 totalPolygonLevel = playerData.levelOfPolygons[0];
            uint256 polygonLevelMultiplier = (1 + 2*(polygonLevel/50)) * (1 + 5*(totalPolygonLevel/500));

            uint256 normalUpgradesMultiplier = 1 + playerData.levelOfUpgrades[0];

            uint256 ascensionUpgradesMultiplier = 1 + playerData.levelOfAscensionPerks[0];

            BigNumber memory polygonLinesPerSecond = BigNumbers.init(basePolygonLinesPerSecond, false)
                .mul(BigNumbers.init(polygonLevel, false))
                .mul(BigNumbers.init(polygonLevelMultiplier, false))
                .mul(BigNumbers.init(normalUpgradesMultiplier, false))
                .mul(BigNumbers.init(ascensionUpgradesMultiplier, false));

            linesPerSecond = linesPerSecond.add(polygonLinesPerSecond);
        }

        // Compute the player's lines
        uint256 timePassed = block.timestamp - playerData.timestampLastUpdate;
        BigNumber memory newLinesSinceLastUpdate = linesPerSecond.mul(BigNumbers.init(timePassed, false));

        // Update the player's data
        playersData[msg.sender].linesLastUpdate = playerData.linesLastUpdate.add(newLinesSinceLastUpdate);
        playersData[msg.sender].totalLinesThisAscension = playerData.totalLinesThisAscension.add(newLinesSinceLastUpdate);
    }

}