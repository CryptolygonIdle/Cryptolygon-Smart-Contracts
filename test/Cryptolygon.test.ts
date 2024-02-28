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
    Circle
} from "../typechain-types";

import { deployDiamond } from "../scripts/deploy.ts"
import { getSelectors } from "../scripts/libraries/diamond.ts"

describe("CryptolygonIdleDiamond", function () {
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

    async function resetDiamondDeploy() {
        [cryptolygonIdleDiamond, Circle] = await deployDiamond();
        AscensionFacet = await ethers.getContractAt("AscensionFacet", cryptolygonIdleDiamond.target);
        DiamondCutFacet = await ethers.getContractAt("DiamondCutFacet", cryptolygonIdleDiamond.target);
        DiamondLoupeFacet = await ethers.getContractAt("DiamondLoupeFacet", cryptolygonIdleDiamond.target);
        OwnershipFacet = await ethers.getContractAt("OwnershipFacet", cryptolygonIdleDiamond.target);
        PolygonsFacet = await ethers.getContractAt("PolygonsFacet", cryptolygonIdleDiamond.target);
        PlayersFacet = await ethers.getContractAt("PlayersFacet", cryptolygonIdleDiamond.target);
        UpgradesFacet = await ethers.getContractAt("UpgradesFacet", cryptolygonIdleDiamond.target);
        UtilsFacet = await ethers.getContractAt("UtilsFacet", cryptolygonIdleDiamond.target);
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

            expect(polygonsProperties).to.have.lengthOf(8);
            expect(polygonsProperties[0]).to.deep.equal([(2n ** 256n) - 1n, 0n]);
            expect(polygonsProperties[1]).to.deep.equal([1n, 2n]);
            expect(polygonsProperties[2]).to.deep.equal([20n, 5n]);
            expect(polygonsProperties[3]).to.deep.equal([400n, 20n]);
            expect(polygonsProperties[4]).to.deep.equal([8000n, 50n]);
            expect(polygonsProperties[5]).to.deep.equal([160000n, 200n]);
            expect(polygonsProperties[6]).to.deep.equal([3200000n, 1000n]);
            expect(polygonsProperties[7]).to.deep.equal([64000000n, 5000n]);
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

        it("should have all the facets functions", async function () {
            // Retrieve all the Facet objects from the deployed diamond
            const facetList = await DiamondLoupeFacet.facets();

            // Prepare a map of facet addresses and their corresponding function selectors
            const facetAddressSelectorsMap: Map<string, string[]> = new Map();
            for (const [index, facet] of facetList.entries()) {
                const facetAddress = facet.facetAddress;

                // Get the facet contract interface based on the facet address
                let facetContract: any;
                switch (facetAddress.toLowerCase()) {
                    case String(AscensionFacet.target).toLowerCase():
                        facetContract = AscensionFacet;
                        break;
                    case String(DiamondCutFacet.target).toLowerCase():
                        facetContract = DiamondCutFacet;
                        break;
                    case String(DiamondLoupeFacet.target).toLowerCase():
                        facetContract = DiamondLoupeFacet;
                        break;
                    case String(OwnershipFacet.target).toLowerCase():
                        facetContract = OwnershipFacet;
                        break;
                    case String(PolygonsFacet.target).toLowerCase():
                        facetContract = PolygonsFacet;
                        break;
                    case String(PlayersFacet.target).toLowerCase():
                        facetContract = PlayersFacet;
                        break;
                    case String(UpgradesFacet.target).toLowerCase():
                        facetContract = UpgradesFacet;
                        break;
                    case String(UtilsFacet.target).toLowerCase():
                        facetContract = UtilsFacet;
                        break;
                    default:
                        throw new Error(`Unknown facet address: ${facetAddress}`);
                }

                // Get the function selectors for the facet contract
                const selectors = await getSelectors(facetContract);
                facetAddressSelectorsMap.set(facetAddress, selectors);
            }

            // Compare the function selectors obtained from the facet's contract interface with the function selectors stored in the Facet objects
            for (const [index, facet] of facetList.entries()) {
                const facetAddress = facet.facetAddress;
                const expectedSelectors = facetAddressSelectorsMap.get(facetAddress);
                const storedSelectors = facet.functionSelectors.map((selector: string) => "0x" + selector.toString());

                expect(storedSelectors).to.deep.equal(expectedSelectors);
            }

        });
    });
});
