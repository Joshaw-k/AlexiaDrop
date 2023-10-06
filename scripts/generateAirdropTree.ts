import MerkleTree from "merkletreejs";
import csv from "csv-parser";
import * as fs from "fs";
import path from "path";
import { solidityPackedKeccak256, keccak256 } from "ethers";

export interface IClaimersProof {
  leaf: string;
  proof: string[];
}

export interface IClaimersData {
  address: string;
  amount: number;
}

const csvfile = path.join(__dirname, "airdropData/data.csv");

async function generateMerkleTree(csvFilePath: string): Promise<void> {
  const data: IClaimersData[] = [];

  // Read the CSV file and store the data in an array
  await new Promise((resolve, reject) => {
    fs.createReadStream(csvFilePath)
      .pipe(csv())
      .on("data", (row: IClaimersData) => {
        data.push(row);
      })
      .on("end", resolve)
      .on("error", reject);
  });
  console.log(data);

  let leaf: string;

  let leaves: string[] = [];

  // Hash the data using the Solidity keccak256 function
  for (const row of data) {
    leaf = solidityPackedKeccak256(
      ["address", "uint256"],
      [row.address, row.amount]
    );

    leaves.push(leaf);
  }

  // Create the Merkle tree
  const tree = new MerkleTree(leaves, keccak256, { sortPairs: true });

  const claimersProofs: { [address: string]: IClaimersProof } = {};
  data.forEach((row, index) => {
    const proof = tree.getProof(leaves[index]);
    claimersProofs[row.address] = {
      leaf: "0x" + leaves[index].toString(),
      proof: proof.map((p) => "0x" + p.data.toString("hex")),
    };
  });

  // Write the Merkle tree and root to a file
  await new Promise<void>((resolve, reject) => {
    fs.writeFile("merkleTree.json", JSON.stringify(claimersProofs), (err) => {
      if (err) {
        reject(err);
      } else {
        resolve();
      }
    });
  });

  // Write a JSON object mapping addresses to data to a file
  const claimersData: { [address: string]: IClaimersData } = {};
  data.forEach((row) => {
    claimersData[row.address] = row;
  });

  await new Promise<void>((resolve, reject) => {
    fs.writeFile("claimersData.json", JSON.stringify(claimersData), (err) => {
      if (err) {
        reject(err);
      } else {
        resolve();
      }
    });
  });
  console.log("0x" + tree.getRoot().toString("hex"));
}

generateMerkleTree(csvfile).catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
