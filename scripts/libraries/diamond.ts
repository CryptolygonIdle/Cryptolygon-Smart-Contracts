import { ethers } from "hardhat";
import { BaseContract, FunctionFragment } from "ethers";
const FacetCutAction = { Add: 0, Replace: 1, Remove: 2 }

// get function selectors from ABI
async function getSelectors(contract: BaseContract) {
    const selectors: string[] = [];
  
    contract.interface.forEachFunction((frag: FunctionFragment) => {
      if (frag.name !== "init" && frag.inputs.length === 1 && frag.inputs[0].type === "bytes") {
        return;
      }
      selectors.push(frag.selector);
    });
    
    return selectors;
  }

// get function selector from function signature
function getSelector(func: any) {
    const abiInterface = new ethers.Interface([func])
    return abiInterface.getFunction(func)?.selector
}

// used with getSelectors to remove selectors from an array of selectors
// functionNames argument is an array of function signatures
function remove(this: any, functionNames: any) {
    const selectors = this.filter((v: any) => {
        for (const functionName of functionNames) {
            if (v === this.contract.interface.getSighash(functionName)) {
                return false
            }
        }
        return true
    })
    selectors.contract = this.contract
    selectors.remove = this.remove
    selectors.get = this.get
    return selectors
}

// used with getSelectors to get selectors from an array of selectors
// functionNames argument is an array of function signatures
function get(this: any, functionNames: any) {
    const selectors = this.filter((v: any) => {
        for (const functionName of functionNames) {
            if (v === this.contract.interface.getSighash(functionName)) {
                return true
            }
        }
        return false
    })
    selectors.contract = this.contract
    selectors.remove = this.remove
    selectors.get = this.get
    return selectors
}

// remove selectors using an array of signatures
function removeSelectors(selectors: any, signatures: any) {
    const iface = new ethers.Interface(signatures.map((v: any) => 'function ' + v))
    const removeSelectors = signatures.map((v: any) => iface.getFunction(v)?.selector)
    selectors = selectors.filter((v: any) => !removeSelectors.includes(v))
    return selectors
}

// find a particular address position in the return value of diamondLoupeFacet.facets()
function findAddressPositionInFacets(facetAddress: any, facets: any) {
    for (let i = 0; i < facets.length; i++) {
        if (facets[i].facetAddress === facetAddress) {
            return i
        }
    }
}

export {
    getSelectors,
    getSelector,
    FacetCutAction,
    remove,
    removeSelectors,
    findAddressPositionInFacets
}
