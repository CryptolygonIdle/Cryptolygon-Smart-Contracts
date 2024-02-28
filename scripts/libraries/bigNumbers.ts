import { ethers } from "hardhat";

export interface BigNumberSolidity {
    val: string;
    neg: boolean;
    bitlen: bigint;
}

export function solidityBigNumberToBigInt(bn: BigNumberSolidity): BigInt {
    const normalizedVal = ethers.hexlify(ethers.zeroPadValue(bn.val, 32 * Math.ceil(bn.val.length / 32)));
    const value = BigInt(normalizedVal);
    return bn.neg ? -value : value;
  } 
