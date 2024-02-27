import { ethers } from "hardhat";
import { expect } from "chai";
import {
    CryptolygonIdleDiamond,
    Circle
} from "../typechain-types";

import { deployDiamond } from "../scripts/deploy.ts"

describe("CryptolygonIdleDiamond", function () {
    let cryptolygonIdleDiamond: CryptolygonIdleDiamond;
    let Circle: Circle;

    beforeEach(async function () {
        [cryptolygonIdleDiamond, Circle] = await deployDiamond();
    });

    it("should deploy the contract correctly", async function () {
        expect(cryptolygonIdleDiamond.target).to.not.equal(0);
    });

    // Add more test cases here

});
