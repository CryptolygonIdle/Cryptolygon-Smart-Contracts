import { ethers } from "hardhat";
import { expect } from "chai";
import {
    CryptolygonIdleDiamond,
    DiamondCutFacet,
    DiamondLoupeFacet,
    OwnershipFacet,
    PolygonsFacet,
    UpgradesFacet,
    AscensionFacet,
    Circle
} from "../typechain-types";

describe("CryptolygonIdleDiamond", function () {
    let cryptolygonIdleDiamond: CryptolygonIdleDiamond;
    let ascensionFacet: AscensionFacet;
    let diamondCutFacet: DiamondCutFacet;
    let diamondLoupeFacet: DiamondLoupeFacet;
    let ownershipFacet: OwnershipFacet;
    let polygonsFacet: PolygonsFacet;
    let upgradesFacet: UpgradesFacet;
    let Circle: Circle;

    beforeEach(async function () {
        cryptolygonIdleDiamond = await ethers.deployContract("CryptolygonIdleDiamond");
        await cryptolygonIdleDiamond.waitForDeployment();
    });

    it("should deploy the contract correctly", async function () {
        expect(cryptolygonIdleDiamond.target).to.not.equal(0);
    });

    // Add more test cases here

});
