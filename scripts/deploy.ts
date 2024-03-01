import { ethers } from 'hardhat'
import { getSelectors, FacetCutAction } from './libraries/diamond.ts'
import {
    CryptolygonIdleDiamond,
    Circle
} from "../typechain-types";

export async function deployDiamond(): Promise<[CryptolygonIdleDiamond, Circle, String[]]> {
    const accounts = await ethers.getSigners()
    const contractOwner = accounts[0]

    // Deploy DiamondInit
    // DiamondInit provides a function that is called when the diamond is upgraded or deployed to initialize state variables
    // Read about how the diamondCut function works in the EIP2535 Diamonds standard
    const DiamondInit = await ethers.getContractFactory('CryptolygonIdleDiamonInit')
    const diamondInit = await DiamondInit.deploy()
    await diamondInit.waitForDeployment()

    // Deploy facets and set the `facetCuts` variable
    const FacetNames = [
        'DiamondCutFacet',
        'DiamondLoupeFacet',
        'OwnershipFacet',
        'AscensionFacet',
        'PolygonsFacet',
        'UpgradesFacet',
        'PlayersFacet',
        'UtilsFacet',
    ]
    // The `facetCuts` variable is the FacetCut[] that contains the functions to add during diamond deployment
    const facetCuts = []
    const facetAddresses: string[] = []
    for (const FacetName of FacetNames) {
        const Facet = await ethers.getContractFactory(FacetName)
        const facet = await Facet.deploy()
        await facet.waitForDeployment()
        facetCuts.push({
            facetAddress: facet.target,
            action: FacetCutAction.Add,
            functionSelectors: await getSelectors(facet)
        })
        facetAddresses.push(String(facet.target))
    }

    // Deploy Circle
    const Circle = await ethers.getContractFactory('Circle')
    const circle = await Circle.deploy(contractOwner.address)
    await circle.waitForDeployment()

    // Creating a function call
    // This call gets executed during deployment and can also be executed in upgrades
    // It is executed with delegatecall on the DiamondInit address.
    let functionCall = diamondInit.interface.encodeFunctionData('init', [circle.target])

    // Setting arguments that will be used in the diamond constructor
    const diamondArgs = {
        owner: contractOwner.address,
        init: diamondInit.target,
        initCalldata: functionCall
    }

    // deploy Diamond
    const Diamond = await ethers.getContractFactory('CryptolygonIdleDiamond')
    const diamond = await Diamond.deploy(facetCuts, diamondArgs)
    await diamond.waitForDeployment()

    // Set Diamond as GAME_ROLE on Circle
    const gameRole = ethers.keccak256(ethers.toUtf8Bytes('GAME_ROLE'))
    await circle.grantRole(gameRole, diamond.target)

    // returning the diamond
    return [diamond, circle, facetAddresses]
}

// We recommend this pattern to be able to use async/await everywhere
// and properly handle errors.
if (require.main === module) {
    deployDiamond()
        .then(() => process.exit(0))
        .catch(error => {
            console.error(error)
            process.exit(1)
        })
}

exports.deployDiamond = deployDiamond