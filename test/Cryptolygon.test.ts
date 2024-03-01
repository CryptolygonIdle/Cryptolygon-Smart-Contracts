import { ethers } from "hardhat";
import { expect } from "chai";
import {
    CryptolygonIdleDiamond,
    AscensionFacet,
    DiamondCutFacet,
    DiamondLoupeFacet,
    OwnershipFacet,
    PolygonsFacet,
    PlayersFacet,
    UpgradesFacet,
    UtilsFacet,
    Circle,
    TestFacet1,
    TestFacet2,
} from "../typechain-types";

import { deployDiamond } from "../scripts/deploy.ts"
import { getSelectors } from "../scripts/libraries/diamond.ts"
import { BigNumberSolidity, solidityBigNumberToBigInt } from "../scripts/libraries/bigNumbers.ts"
import { PlayerDataV1Struct } from "../typechain-types/contracts/interfaces/IPlayersFacet.ts";

function polygonCost(polygonBaseCost: bigint, currentLevel: bigint, amount: bigint): bigint {
    // Cost = polygonBaseCost * 2**polygonCurrentLevel * (2**amountToBuy - 1)
    return polygonBaseCost * (2n ** currentLevel) * ((2n ** amount) - 1n);
}

describe("CryptolygonIdleDiamond", function () {
    let contractOwner: any;

    let cryptolygonIdleDiamond: CryptolygonIdleDiamond;
    let AscensionFacet: AscensionFacet;
    let DiamondCutFacet: DiamondCutFacet;
    let DiamondLoupeFacet: DiamondLoupeFacet;
    let OwnershipFacet: OwnershipFacet;
    let PolygonsFacet: PolygonsFacet;
    let PlayersFacet: PlayersFacet;
    let UpgradesFacet: UpgradesFacet;
    let UtilsFacet: UtilsFacet;
    let Circle: Circle;

    let facetAddresses: String[] = [];

    let testFacet1: TestFacet1;
    let testFacet2: TestFacet2;

    async function resetDiamondDeploy() {
        const accounts = await ethers.getSigners()
        contractOwner = accounts[0];
        [cryptolygonIdleDiamond, Circle, facetAddresses] = await deployDiamond();
        AscensionFacet = await ethers.getContractAt("AscensionFacet", cryptolygonIdleDiamond.target);
        DiamondCutFacet = await ethers.getContractAt("DiamondCutFacet", cryptolygonIdleDiamond.target);
        DiamondLoupeFacet = await ethers.getContractAt("DiamondLoupeFacet", cryptolygonIdleDiamond.target);
        OwnershipFacet = await ethers.getContractAt("OwnershipFacet", cryptolygonIdleDiamond.target);
        PolygonsFacet = await ethers.getContractAt("PolygonsFacet", cryptolygonIdleDiamond.target);
        PlayersFacet = await ethers.getContractAt("PlayersFacet", cryptolygonIdleDiamond.target);
        UpgradesFacet = await ethers.getContractAt("UpgradesFacet", cryptolygonIdleDiamond.target);
        UtilsFacet = await ethers.getContractAt("UtilsFacet", cryptolygonIdleDiamond.target);
    }

    async function startGame() {
        await PlayersFacet.startGame();
    }

    before(async function () {
        await resetDiamondDeploy();
    });

    describe("Diamond Initialisation", function () {
        it("should deploy the contract correctly", async function () {
            expect(cryptolygonIdleDiamond.target).to.not.equal(0);
        });

        it("should initialize polygons properties correctly", async function () {
            const polygonsProperties = await UtilsFacet.getPolygonsProperties();

            expect(polygonsProperties).to.have.lengthOf(7);
            expect(polygonsProperties[0]).to.deep.equal([1n, 2n]);
            expect(polygonsProperties[1]).to.deep.equal([20n, 5n]);
            expect(polygonsProperties[2]).to.deep.equal([400n, 20n]);
            expect(polygonsProperties[3]).to.deep.equal([8000n, 50n]);
            expect(polygonsProperties[4]).to.deep.equal([160000n, 200n]);
            expect(polygonsProperties[5]).to.deep.equal([3200000n, 1000n]);
            expect(polygonsProperties[6]).to.deep.equal([64000000n, 5000n]);
        });

        it("should initialize upgrades properties correctly", async function () {
            const upgradesProperties = await UtilsFacet.getUpgradesProperties();

            expect(upgradesProperties).to.have.lengthOf(4);
            expect(upgradesProperties[0]).to.deep.equal([1n, 1n]);
            expect(upgradesProperties[1]).to.deep.equal([1n, 1n]);
            expect(upgradesProperties[2]).to.deep.equal([1000n, 1n]);
            expect(upgradesProperties[3]).to.deep.equal([1000n, 1n]);
        });

        it("should initialize ascension perks properties correctly", async function () {
            const ascensionPerksProperties = await UtilsFacet.getAscensionPerksProperties();

            expect(ascensionPerksProperties).to.have.lengthOf(3);
            expect(ascensionPerksProperties[0]).to.deep.equal([1n, 1n]);
            expect(ascensionPerksProperties[1]).to.deep.equal([1n, 1n]);
            expect(ascensionPerksProperties[2]).to.deep.equal([10n, 1n]);
        });

        it("should initialize the circle correctly", async function () {
            const circleAddress = await UtilsFacet.getCircleAddress();

            expect(circleAddress).to.equal(Circle.target);
        });

        it("should have the correct owner", async function () {
            const owner = await OwnershipFacet.owner();
            expect(owner).to.equal(contractOwner.address);
        });
    });

    describe("Diamond Administration", function () {

        beforeEach(async function () {
            await resetDiamondDeploy();

            // Deploy contracts
            const TestFacet1 = await ethers.getContractFactory("TestFacet1");
            const TestFacet2 = await ethers.getContractFactory("TestFacet2");
            testFacet1 = await TestFacet1.deploy();
            testFacet2 = await TestFacet2.deploy();
        });

        it("should change the owner correctly", async function () {
            const newOwner = (await ethers.getSigners())[1];
            await OwnershipFacet.transferOwnership(newOwner.address);
            const owner = await OwnershipFacet.owner();
            expect(owner).to.equal(newOwner.address);
        });

        it("should add a new facet correctly", async function () {
            const newFacet = testFacet1;
            const selectors = await getSelectors(newFacet);
            await DiamondCutFacet.diamondCut(
                [{ facetAddress: testFacet1.target, action: 0, functionSelectors: selectors }],
                ethers.ZeroAddress,
                "0x"
            );
            const facetFunctionSelectors = await DiamondLoupeFacet.facetFunctionSelectors(newFacet.target);
            expect(facetFunctionSelectors).to.deep.equal(selectors);

            // Check if the new facet is callable
            const returnTest1 = await testFacet1.test1();
            const returnTest2 = await testFacet1.test2();

            expect(returnTest1).to.equal(1);
            expect(returnTest2).to.equal(3);
        });

        it("should remove a facet correctly", async function () {
            const newFacet = testFacet1;
            const selectors = await getSelectors(newFacet);
            await DiamondCutFacet.diamondCut(
                [{ facetAddress: testFacet1.target, action: 0, functionSelectors: selectors }],
                ethers.ZeroAddress,
                "0x"
            );

            // Remove the facet
            await DiamondCutFacet.diamondCut(
                [{ facetAddress: ethers.ZeroAddress, action: 2, functionSelectors: selectors }],
                ethers.ZeroAddress,
                "0x"
            );
            const facetFunctionSelectorsAfterRemoval = await DiamondLoupeFacet.facetFunctionSelectors(newFacet.target);
            expect(facetFunctionSelectorsAfterRemoval).to.have.lengthOf(0);
        });

        it("should remove a single function from a facet correctly", async function () {
            const newFacet = testFacet1;
            const selectors = await getSelectors(newFacet);
            await DiamondCutFacet.diamondCut(
                [{ facetAddress: testFacet1.target, action: 0, functionSelectors: selectors }],
                ethers.ZeroAddress,
                "0x"
            );

            // Remove the function
            await DiamondCutFacet.diamondCut(
                [{ facetAddress: ethers.ZeroAddress, action: 2, functionSelectors: [selectors[0]] }],
                ethers.ZeroAddress,
                "0x"
            );
            const facetFunctionSelectorsAfterRemoval = await DiamondLoupeFacet.facetFunctionSelectors(newFacet.target);
            expect(facetFunctionSelectorsAfterRemoval).to.have.lengthOf(1);
            expect(facetFunctionSelectorsAfterRemoval[0]).to.equal(selectors[1]);
        });

        it("should upgrade a facet correctly", async function () {
            const newFacet = testFacet1;
            const selectors = await getSelectors(newFacet);
            await DiamondCutFacet.diamondCut(
                [{ facetAddress: testFacet1.target, action: 0, functionSelectors: selectors }],
                ethers.ZeroAddress,
                "0x"
            );

            // Upgrade the facet
            const newFacet2 = testFacet2;
            const selectors2 = await getSelectors(newFacet2);
            await DiamondCutFacet.diamondCut(
                [{ facetAddress: testFacet2.target, action: 1, functionSelectors: selectors2 }],
                ethers.ZeroAddress,
                "0x"
            );

            const facetFunctionSelectorsAfterUpgrade = await DiamondLoupeFacet.facetFunctionSelectors(newFacet2.target);
            expect(facetFunctionSelectorsAfterUpgrade).to.deep.equal(selectors2);

            // Check if the new facet is callable
            const returnTest1 = await testFacet2.test1();
            const returnTest2 = await testFacet2.test2();

            expect(returnTest1).to.equal(10n);
            expect(returnTest2).to.equal(30n);
        });

        it("should only allow the owner to change the owner", async function () {
            const newOwner = (await ethers.getSigners())[1];
            await expect(OwnershipFacet.connect(newOwner).transferOwnership(newOwner.address)).to.be.revertedWithCustomError(OwnershipFacet, "NotContractOwner");
        });

        it("should only allow the owner to add a new facet", async function () {
            const newFacet = testFacet1;
            const selectors = await getSelectors(newFacet);
            await expect(DiamondCutFacet.connect((await ethers.getSigners())[1]).diamondCut(
                [{ facetAddress: testFacet1.target, action: 0, functionSelectors: selectors }],
                ethers.ZeroAddress,
                "0x"
            )).to.be.revertedWithCustomError(OwnershipFacet, "NotContractOwner");
        });
    });

    describe("Players Facet", function () {

        it("Should start the game correctly", async function () {
            await PlayersFacet.startGame();

            const block = await ethers.provider.getBlock("latest");
            const timestamp = block ? block.timestamp : 0;
            const playerData = await PlayersFacet.getPlayerData(contractOwner.address);

            expect(playerData[0][0]).to.equal(1);
            expect(playerData[3]).to.equal(1);
            expect(playerData[4]).to.equal(timestamp);
        });

        it("Should generate the correct amount of polygons", async function () {
            await resetDiamondDeploy();
            await startGame();

            const initialPlayerData = await PlayersFacet.getPlayerData(contractOwner.address);
            const initialTimestamp = initialPlayerData[4];

            //Skip 1h
            await ethers.provider.send("evm_increaseTime", [3600]);
            await ethers.provider.send("evm_mine", []);

            const playerData = await PlayersFacet.getPlayerData(contractOwner.address);
            const playerLines = solidityBigNumberToBigInt(playerData[5]);
            const playerTotalLines = solidityBigNumberToBigInt(playerData[6]);
            const timestamp = playerData[4];
            const timePassed = timestamp - initialTimestamp;
            const expectedLines = 2n * timePassed;

            expect(playerLines).to.equal(expectedLines);
            expect(playerTotalLines).to.equal(expectedLines);

        });

        it("Should update the player's data correctly", async function () {
            await resetDiamondDeploy();
            await startGame();

            const initialPlayerData = await PlayersFacet.getPlayerData(contractOwner.address);
            const initialTimestamp = initialPlayerData[4];

            //Skip 1h
            await ethers.provider.send("evm_increaseTime", [3600]);
            await ethers.provider.send("evm_mine", []);

            await PlayersFacet.updatePlayerData(contractOwner.address);

            const playerData = await PlayersFacet.getPlayerData(contractOwner.address);
            const playerLines = solidityBigNumberToBigInt(playerData[5]);
            const playerTotalLines = solidityBigNumberToBigInt(playerData[6]);
            const timestamp = playerData[4];
            const timePassed = timestamp - initialTimestamp;
            const expectedLines = 2n * timePassed;

            expect(playerLines).to.equal(expectedLines);
            expect(playerTotalLines).to.equal(expectedLines);
        });
    });

    describe("Polygons Facet", function () {

        it("Should return the correct cost for a polygon (without upgrades)", async function () {
            const polygonId = 0;
            const costOneLevel = solidityBigNumberToBigInt(await PolygonsFacet.getPolygonLevelUpCost(polygonId, 1, 1));
            const costTwoLevels = solidityBigNumberToBigInt(await PolygonsFacet.getPolygonLevelUpCost(polygonId, 1, 2));
            const costTenLevels = solidityBigNumberToBigInt(await PolygonsFacet.getPolygonLevelUpCost(polygonId, 1, 10));
            const costTenLevelsFromTen = solidityBigNumberToBigInt(await PolygonsFacet.getPolygonLevelUpCost(polygonId, 10, 10));

            const polygonBaseCost = (await UtilsFacet.getPolygonsProperties())[polygonId][0];
            const currentLevel = 1n;
            const amountOne = 1n;
            const amountTwo = 2n;
            const amountTen = 10n;

            const expectedCostOneLevel = polygonCost(polygonBaseCost, currentLevel, amountOne);
            const expectedCostTwoLevels = polygonCost(polygonBaseCost, currentLevel, amountTwo);
            const expectedCostTenLevels = polygonCost(polygonBaseCost, currentLevel, amountTen);
            const expectedCostTenLevelsFromTen = polygonCost(polygonBaseCost, 10n, amountTen);

            expect(costOneLevel).to.equal(expectedCostOneLevel);
            expect(costTwoLevels).to.equal(expectedCostTwoLevels);
            expect(costTenLevels).to.equal(expectedCostTenLevels);
            expect(costTenLevelsFromTen).to.equal(expectedCostTenLevelsFromTen);
        });

        it("Should perform the level up correctly", async function () {
            await resetDiamondDeploy();
            await startGame();

            await ethers.provider.send("evm_increaseTime", [3600]);
            await ethers.provider.send("evm_mine", []);

            // Test the level up of the first polygon
            const polygonId = 0;
            const amount = 2n;
            await PolygonsFacet.levelUpPolygons([polygonId], [amount]);

            const playerData = await PlayersFacet.getPlayerData(contractOwner.address);
            const playerPolygons = playerData[3];
            const playerPolygonOneLevel = playerData[0][polygonId];

            expect(playerPolygons).to.equal(1n + amount);
            expect(playerPolygonOneLevel).to.equal(1n + amount);

            // Test the level up of the second polygon
            await PolygonsFacet.levelUpPolygons([polygonId + 1], [amount]);

            const playerData2 = await PlayersFacet.getPlayerData(contractOwner.address);
            const playerPolygons2 = playerData2[3];
            const playerPolygonTwoLevel = playerData2[0][polygonId + 1];

            expect(playerPolygons2).to.equal(1n + amount + amount);
            expect(playerPolygonTwoLevel).to.equal(amount);

            // Test the level up of the third polygon
            await PolygonsFacet.levelUpPolygons([polygonId + 2], [amount]);

            const playerData3 = await PlayersFacet.getPlayerData(contractOwner.address);
            const playerPolygons3 = playerData3[3];
            const playerPolygonThreeLevel = playerData3[0][polygonId + 2];

            expect(playerPolygons3).to.equal(1n + amount + amount + amount);
            expect(playerPolygonThreeLevel).to.equal(amount);

        });

        it("Should revert if the player doesn't have enough lines", async function () {
            await resetDiamondDeploy();
            await startGame();

            await expect(PolygonsFacet.levelUpPolygons([0], [2])).to.be.revertedWithCustomError(PolygonsFacet, "NotEnoughLinesToLevelUp");
        });

        it("Should revert if arguments are wrong", async function () {
            await resetDiamondDeploy();
            await startGame();

            await ethers.provider.send("evm_increaseTime", [3600]);
            await ethers.provider.send("evm_mine", []);

            await expect(PolygonsFacet.levelUpPolygons([0, 0], [1])).to.be.revertedWithCustomError(PolygonsFacet, "InvalidArguments");
            await expect(PolygonsFacet.levelUpPolygons([0], [1, 1])).to.be.revertedWithCustomError(PolygonsFacet, "InvalidArguments");
            await expect(PolygonsFacet.levelUpPolygons([0], [0])).to.be.revertedWithCustomError(PolygonsFacet, "InvalidArguments");
            await expect(PolygonsFacet.levelUpPolygons([20], [0])).to.be.revertedWithCustomError(PolygonsFacet, "InvalidArguments");

            await expect(PolygonsFacet.levelUpPolygons([2], [1])).to.be.revertedWithCustomError(PolygonsFacet, "PolygonLevelUpNotAllowed");

        });
    });

    describe("Upgrades Facet", function () {

        function upgradeCost(upgradeBaseCost: bigint, currentLevel: bigint, amount: bigint): bigint {
            // Cost = upgradeBaseCost * 2**currentLevel * (2**amountToBuy - 1)
            return upgradeBaseCost * (2n ** currentLevel) * ((2n ** amount) - 1n);
        }

        it("Should return the correct cost for an upgrade", async function () {
            const upgradeId = 0;
            const costOneLevel = solidityBigNumberToBigInt(await UpgradesFacet.getUpgradeLevelUpCost(upgradeId, 1, 1));
            const costTwoLevels = solidityBigNumberToBigInt(await UpgradesFacet.getUpgradeLevelUpCost(upgradeId, 1, 2));
            const costTenLevels = solidityBigNumberToBigInt(await UpgradesFacet.getUpgradeLevelUpCost(upgradeId, 1, 10));
            const costTenLevelsFromTen = solidityBigNumberToBigInt(await UpgradesFacet.getUpgradeLevelUpCost(upgradeId, 10, 10));

            const upgradeBaseCost = (await UtilsFacet.getUpgradesProperties())[upgradeId][0];
            const currentLevel = 1n;
            const amountOne = 1n;
            const amountTwo = 2n;
            const amountTen = 10n;

            const expectedCostOneLevel = upgradeCost(upgradeBaseCost, currentLevel, amountOne);
            const expectedCostTwoLevels = upgradeCost(upgradeBaseCost, currentLevel, amountTwo);
            const expectedCostTenLevels = upgradeCost(upgradeBaseCost, currentLevel, amountTen);
            const expectedCostTenLevelsFromTen = upgradeCost(upgradeBaseCost, 10n, amountTen);

            expect(costOneLevel).to.equal(expectedCostOneLevel);
            expect(costTwoLevels).to.equal(expectedCostTwoLevels);
            expect(costTenLevels).to.equal(expectedCostTenLevels);
            expect(costTenLevelsFromTen).to.equal(expectedCostTenLevelsFromTen);
        });

        it("Should perform the level up correctly", async function () {
            await resetDiamondDeploy();
            await startGame();

            await ethers.provider.send("evm_increaseTime", [3600]);
            await ethers.provider.send("evm_mine", []);

            // Test the level up of the first upgrade
            const upgradeId = 0;
            const amount = 2n;
            await UpgradesFacet.buyUpgrades([upgradeId], [amount]);

            const playerData = await PlayersFacet.getPlayerData(contractOwner.address);
            const playerUpgrades = playerData[2][upgradeId];

            expect(playerUpgrades).to.equal(amount);

            // Test the level up of the second upgrade
            await UpgradesFacet.buyUpgrades([upgradeId + 1], [amount]);

            const playerData2 = await PlayersFacet.getPlayerData(contractOwner.address);
            const playerUpgrades2 = playerData2[2][upgradeId + 1];

            expect(playerUpgrades2).to.equal(amount);

            // Test the level up of the third upgrade
            await UpgradesFacet.buyUpgrades([upgradeId + 2], [amount]);

            const playerData3 = await PlayersFacet.getPlayerData(contractOwner.address);
            const playerUpgrades3 = playerData3[2][upgradeId + 2];

            expect(playerUpgrades3).to.equal(amount);
        });

        it("Should revert if the player doesn't have enough lines", async function () {
            await resetDiamondDeploy();
            await startGame();

            await expect(UpgradesFacet.buyUpgrades([0], [4])).to.be.revertedWithCustomError(UpgradesFacet, "NotEnoughLinesToBuyUpgrade");
        });

        it("Should revert if arguments are wrong", async function () {
            await resetDiamondDeploy();
            await startGame();

            await ethers.provider.send("evm_increaseTime", [3600]);
            await ethers.provider.send("evm_mine", []);

            await expect(UpgradesFacet.buyUpgrades([0, 0], [1])).to.be.revertedWithCustomError(UpgradesFacet, "InvalidArguments");
            await expect(UpgradesFacet.buyUpgrades([0], [1, 1])).to.be.revertedWithCustomError(UpgradesFacet, "InvalidArguments");
            await expect(UpgradesFacet.buyUpgrades([0], [0])).to.be.revertedWithCustomError(UpgradesFacet, "InvalidArguments");
            await expect(UpgradesFacet.buyUpgrades([20], [0])).to.be.revertedWithCustomError(UpgradesFacet, "InvalidArguments");

        });
    });

    describe("Ascension Facet", function () {

        function ascensionCost(ascensionPerkId: bigint, currentLevel: bigint, amount: bigint): bigint {
            // CostNLevels = perkId^perkId * (perkCurrentLevel + 1) + perkId^perkId * (perkCurrentLevel + 2) + ... + perkId^perkId * (perkCurrentLevel + N) = perkId^perkId * (N*perkCurrentLevel + N*(N+1)/2)
            return ascensionPerkId ** ascensionPerkId * amount * (currentLevel + (amount + 1n) / 2n) * (10n ** 18n);
        }

        function ascensionCircleToGive(totalLinesThisAscension: bigint, totalLinesPreviousAscensions: bigint): bigint {
            // Log2(totalLinesPreviousAscensions + totalLinesThisAscension) - Log2(totalLinesPreviousAscensions)
            const minimumLines = 2n ** 35n;
            const minimumLinesLog2 = 35;
            let circleToGive = 0;
            if (totalLinesPreviousAscensions == 0n || totalLinesThisAscension < minimumLines) {
                if (totalLinesThisAscension < minimumLines) {
                    return 0n;
                }
                else {
                    circleToGive = Math.max(0, Math.log2(Number(totalLinesThisAscension)) - minimumLinesLog2);
                }
            }
            else {
                circleToGive = Math.max(0, Math.log2(Number(totalLinesPreviousAscensions + totalLinesThisAscension)) - minimumLinesLog2) - Math.log2(Number(totalLinesPreviousAscensions));
            }
            return BigInt(Math.floor(circleToGive) * 10 ** 18);

        }

        async function simulateGame(timeInDays: number) {

            const polygonsProperties = await UtilsFacet.getPolygonsProperties();

            for (let i = 0; i < timeInDays; i++) {
                ethers.provider.send("evm_increaseTime", [3600 * 24]);
                ethers.provider.send("evm_mine", []);

                // Compute the amount of buyable polygons
                const playerData = await PlayersFacet.getPlayerData(contractOwner.address);
                const currentLines = solidityBigNumberToBigInt(playerData[5]);
                const lengthLevelOfPolygons = (playerData[0]).length + 1 < polygonsProperties.length ? (playerData[0]).length : polygonsProperties.length - 1;

                for (let j = 0; j < lengthLevelOfPolygons + 1; j++) {
                    const polygonLevel = j == lengthLevelOfPolygons ? 0n : playerData[0][j];

                    let temp = (currentLines * ((1n * 10000n) / (BigInt(lengthLevelOfPolygons) + 2n - BigInt(j))) / (10000n * polygonsProperties[j][0] * (2n ** polygonLevel))) + 1n;
                    let maxBuyAmount = Math.floor(Math.log2(Number(temp)));

                    if (maxBuyAmount - 1 > 0) {
                        try {
                            await PolygonsFacet.levelUpPolygons([j], [BigInt(maxBuyAmount - 1)]);
                        } catch (error) {}
                    }
                }
            }
        }

        it("Should return the correct cost for an ascension perk", async function () {
            const ascensionId = 0;
            const costOneLevel = await AscensionFacet.getAscensionPerkLevelUpCost(ascensionId, 1, 1);
            const costTwoLevels = await AscensionFacet.getAscensionPerkLevelUpCost(ascensionId, 1, 2);
            const costTenLevels = await AscensionFacet.getAscensionPerkLevelUpCost(ascensionId, 1, 10);
            const costTenLevelsFromTen = await AscensionFacet.getAscensionPerkLevelUpCost(ascensionId, 10, 10);

            const ascensionBaseCost = (await UtilsFacet.getAscensionPerksProperties())[ascensionId][0];
            const currentLevel = 1n;
            const amountOne = 1n;
            const amountTwo = 2n;
            const amountTen = 10n;

            const expectedCostOneLevel = ascensionCost(ascensionBaseCost, currentLevel, amountOne);
            const expectedCostTwoLevels = ascensionCost(ascensionBaseCost, currentLevel, amountTwo);
            const expectedCostTenLevels = ascensionCost(ascensionBaseCost, currentLevel, amountTen);
            const expectedCostTenLevelsFromTen = ascensionCost(ascensionBaseCost, 10n, amountTen);

            expect(costOneLevel).to.equal(expectedCostOneLevel);
            expect(costTwoLevels).to.equal(expectedCostTwoLevels);
            expect(costTenLevels).to.equal(expectedCostTenLevels);
            expect(costTenLevelsFromTen).to.equal(expectedCostTenLevelsFromTen);
        });

        it("Should buy the ascension perk correctly", async function () {
            await resetDiamondDeploy();
            await startGame();
            await simulateGame(1);

            await ethers.provider.send("evm_increaseTime", [2**35]);
            await ethers.provider.send("evm_mine", []);

            await AscensionFacet.ascend();

            const playerCircleBefore = await Circle.balanceOf(contractOwner.address);

            const ascensionPerksProperties = await UtilsFacet.getAscensionPerksProperties();
            const perkCost1 = ascensionPerksProperties[0][0] * 10n**18n;
            const perkCost2 = ascensionPerksProperties[1][0] * 10n**18n;
            
            const ascensionId1 = 0;
            const ascensionId2 = 1;
            const amount = 1n;
            await AscensionFacet.buyAscensionPerks([ascensionId1, ascensionId2], [amount, amount]);

            const playerCircleAfter = await Circle.balanceOf(contractOwner.address);
            const playerData = await PlayersFacet.getPlayerData(contractOwner.address);
            const playerPerks1 = playerData[1][ascensionId1];
            const playerPerks2 = playerData[1][ascensionId2];

            expect(playerPerks1).to.equal(amount);
            expect(playerPerks2).to.equal(amount);
            expect(playerCircleAfter).to.equal(playerCircleBefore - perkCost1 - perkCost2);
        });

        it("Should ascend correctly", async function () {
            await resetDiamondDeploy();
            await startGame();
            await simulateGame(5);
            
            await ethers.provider.send("evm_increaseTime", [2**35]);
            await ethers.provider.send("evm_mine", []);
            // Get the player's data before the ascension
            const playerDataBefore = await PlayersFacet.getPlayerData(contractOwner.address);
            const playerTotalLinesThisAscension = solidityBigNumberToBigInt(playerDataBefore[6]);
            const playerTotalLinesPreviousAscensions = solidityBigNumberToBigInt(playerDataBefore[7]);
            const expectedCircleToGive = ascensionCircleToGive(playerTotalLinesThisAscension, playerTotalLinesPreviousAscensions);

            // Test the ascension
            await AscensionFacet.ascend();

            // Get the player's data after the ascension
            const playerDataAfter = await PlayersFacet.getPlayerData(contractOwner.address);
            const playerTotalLinesThisAscensionAfter = solidityBigNumberToBigInt(playerDataAfter[6]);
            const playerCircles = await Circle.balanceOf(contractOwner.address);
            const ascensionCount = playerDataAfter[8];
            const playerPolygons = playerDataAfter[0];

            expect(playerTotalLinesThisAscensionAfter).to.equal(0n);
            expect(playerCircles).to.equal(expectedCircleToGive);
            expect(ascensionCount).to.equal(1n);
            expect(playerPolygons).to.deep.equal([1n]);

        });
    });

    describe("Utils Facet", function () {

    });

    describe("Circle", function () {

    });
});
