const { Axiom } = require("@axiom-crypto/core")
const { ethers } = require('ethers')

const specAddr = "blah blah blah";

const config = {
    providerUri: 'https://rpc.ankr.com/eth_goerli',
    version: "v1",    
    chainId: 5,
    mock: true
};

const ax = new Axiom(config);
const qb = ax.newQueryBuilder();

console.log(qb)

// 
async function run() {
  // block query for 
  const blockNumber = 9070887
  const blockHashWitness = await ax.block.getBlockHashWitness(blockNumber)
  const blockRlpHeader = await ax.block.getBlockRlpHeader(blockNumber)
  
  const signer = ethers.providers.JsonRpcSigner('private_key')

  const provider = ethers.providers.JsonRpcProvider('https://rpc.ankr.com/eth_goerli')
  
  signer.attach(provider)

  // call the local contract function
  const contract = new ethers.Contract(specAddr, [], signer);
  const tx = await contract.provideGasPrice(blockHashWitness,blockRlpHeader)
  await tx.wait()
  
}

run().catch(console.error)
