const AlgorandBlockchain = require("./blockchains/AlgorandBlockchain").AlgorandBlockchain

class Blockchain {
  constructor(envs) {
    this.envs = envs
    this.blockchainNetwork = envs.blockchainNetwork
    if (["algorand", "algorand_test", "algorand_beta"].indexOf(this.blockchainNetwork) > -1) {
      this.klass = new AlgorandBlockchain(this.envs)
    } else if (["ethereum", "ethereum_ropsten"].indexOf(this.blockchainNetwork) > -1) {
      this.klass = new EthereumBlockchain(this.envs)
    } else {
      this.klass = undefined
    }
  }

  async generateNewWallet() {
    return await this.klass.generateNewWallet()
  }
}
exports.Blockchain = Blockchain
