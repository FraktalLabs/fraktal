import { deploy } from './deploy-deps.js'
import fs from 'fs'

(async () => {
  try {
      console.log("Deploying contracts... w/ sequencer address: ", process.env.SEQUENCER_ADDRESS)
      var result = await deploy('Test', [], 'http://localhost:8545')
      console.log(result)
      console.log("Deployed Test contract to : ", result.address)
      var jsonOutput = "{\"address\": \"" + result.address + "\"}"
      // Write the contract address to a file
      fs.writeFileSync('./builds/test-address.txt', jsonOutput)

      result = await deploy('PrintNumbers', [], 'http://localhost:8545')
      console.log(result)
      console.log("Deployed PrintNumbers contract to : ", result.address)
      jsonOutput = "{\"address\": \"" + result.address + "\"}"
      // Write the contract address to a file
      fs.writeFileSync('./builds/print-numbers-address.txt', jsonOutput)
  } catch (e) {
      console.log(e.message)
  }

  process.exit(0)
})()

