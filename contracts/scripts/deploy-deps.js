import fs from 'fs'
import Web3 from 'web3'
import web3_contract from 'web3-eth-contract'
import net from 'net'
const { Contract, ContractSendMethod, Options } = web3_contract
//import HDWalletProvider from "truffle-hdwallet-provider"
//import { Contract, ContractSendMethod, Options } from 'web3-eth-contract'

/**
 * Deploy the given contract
 * @param {string} contractName name of the contract to deploy
 * @param {Array<any>} args list of constructor' parameters
 * @param {string} from account used to send the transaction
 * @param {number} gas gas limit
 * @return {Options} deployed contract
 */
export const deploy = async (contractName, args, url, from, gas) => {
  console.log('deploying', contractName, 'with args', args, 'from', from, 'gas', gas)

  // if url starts with http, use http provider else use ipc provider
  var web3
  if (url.startsWith('http')) {
    web3 = new Web3(new Web3.providers.HttpProvider(url))
  } else {
    web3 = new Web3(new Web3.providers.IpcProvider(url, net))
  }
  console.log(`deploying ${contractName}`)

  // Load contract from builds folder using grep to find the right file with contract name
  const abiPath = fs.readdirSync('./builds').filter(file => file.match(new RegExp(`${contractName}.abi`)))

  //const abiPath = `./builds/contracts_${contractName}_sol_${contractName}.abi`
  const abi = JSON.parse(fs.readFileSync("./builds/" + abiPath[0], 'utf8'))
  //const bytecodePath = `./builds/contracts_${contractName}_sol_${contractName}.bin`
  const bytecodePath = fs.readdirSync('./builds').filter(file => file.match(new RegExp(`${contractName}.bin`)))
  const bytecode = fs.readFileSync("./builds/" + bytecodePath[0], 'utf8')
  console.log('bytecode', bytecode)

  const contract = new web3.eth.Contract(abi)
  console.log('contract', contract)
  const accounts = await web3.eth.getAccounts()
  console.log('accounts', accounts)

  const contractSend = contract.deploy({
    data: bytecode,
    arguments: args
  })

  const newContractInstance = await contractSend.send({
    from: from || accounts[0],
    gas: gas || 300000000,
  })

  return newContractInstance.options
}

