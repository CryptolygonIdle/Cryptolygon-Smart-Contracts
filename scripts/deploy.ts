import { ethers } from 'hardhat'

import { getSelectors, FacetCutAction } from './libraries/diamond.ts'

async function deployDiamond() {
    const accounts = await ethers.getSigners()
    const contractOwner = accounts[0]

    // Deploy DiamondInit
    // DiamondInit provides a function that is called when the diamond is upgraded or deployed to initialize state variables
    // Read about how the diamondCut function works in the EIP2535 Diamonds standard
    const DiamondInit = await ethers.getContractFactory('CryptolygonIdleDiamonInit')
    const diamondInit = await DiamondInit.deploy()
    await diamondInit.waitForDeployment()
    console.log('CryptolygonIdleDiamonInit deployed:', diamondInit.target)

    // Deploy facets and set the `facetCuts` variable
    console.log('')
    console.log('Deploying facets')
    const FacetNames = [
        'DiamondCutFacet',
        'DiamondLoupeFacet',
        'OwnershipFacet',
        'AscensionFacet',
        'PolygonFacet',
        'UpgradeFacet',
    ]
    // The `facetCuts` variable is the FacetCut[] that contains the functions to add during diamond deployment
    const facetCuts = []
    for (const FacetName of FacetNames) {
        const Facet = await ethers.getContractFactory(FacetName)
        const facet = await Facet.deploy()
        await facet.waitForDeployment()
        console.log(`${FacetName} deployed: ${facet.target}`)
        facetCuts.push({
            facetAddress: facet.target,
            action: FacetCutAction.Add,
            functionSelectors: getSelectors(facet)
        })
    }

    // Deploy Circle
    const Circle = await ethers.getContractFactory('Circle')
    const circle = await Circle.deploy()
    await circle.waitForDeployment()
    console.log('Circle deployed:', circle.target)

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
    console.log()
    console.log('Diamond deployed:', diamond.target)

    // returning the address of the diamond
    return diamond.target
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