import jQuery from 'jquery'
import config from 'networks/qtum/config'
import Wallet from 'networks/qtum/ledger/wallet'
import debugLog from 'src/javascripts/debugLog'
import caValidator from 'wallet-address-validator'

const transferQtumCoins = async function(award) { // award in JSON
  const fee = 0.0015
  const network = award.token.blockchain_network.replace('qtum_', '')
  const recipientAddress = award.account.qtum_wallet
  let amount = parseFloat(award.total_amount)

  if (!recipientAddress || recipientAddress === '' || amount <= 0 || !(network === 'mainnet' || network === 'testnet')) {
    return
  }
  try {
    const networkType = network === 'mainnet' ? 'prod' : 'testnet'
    const addressValid = caValidator.validate(recipientAddress, 'QTUM', networkType)
    if (addressValid) {
      window.alertMsg('#metamaskModal1', 'Waiting...')
      const txHash = await submitTransaction(network, recipientAddress, amount, fee)
      debugLog(`transaction address: ${txHash}`)
      if (txHash) {
        jQuery.post('/projects/' + award.project.id + '/awards/' + award.id + '/update_transaction_address', { tx: txHash })
      }
      window.foundationCmd('#metamaskModal1', 'close')
      return txHash
    }
  } catch (err) {
    console.log(err)
    window.alertMsg('#metamaskModal1', err.message)
    if (jQuery('body.projects-show').length > 0) {
      jQuery('.flash-msg').html('The tokens have been awarded but not transferred. You can transfer tokens on the blockchain on the <a href="/projects/' + award.project.id + '/awards">awards</a> page.')
    }
  }
}

// amount, fee in QTUM
// network: 'mainnet' or 'testnet'
const submitTransaction = async function(network, to, amount, fee) {
  config.set('network', network)
  const server = require('networks/qtum/server').default
  let path
  switch (network) {
    case 'testnet':
      path = "m/44'/1'/0'/0"
      break
    case 'mainnet':
      path = "m/44'/88'/0'/0"
      break
    default:
  }
  const ledger = await Wallet.connectLedger()
  debugLog('ledger ...........')
  debugLog(ledger)
  const hdNode = await Wallet.restoreHdNodeFromLedgerPath(ledger, path)

  debugLog(hdNode)
  let wallet
  Wallet.restoreFromHdNodeByPage(hdNode, 0, 1).forEach((item) => {
    debugLog('item ...........')
    wallet = item.wallet
    wallet.extend.ledger.path += '/' + item.path
  })
  debugLog(wallet)
  const fromAddress = wallet.info.address
  const info = await server.currentNode().getInfo(fromAddress)
  if (amount + fee >= info.balance) {
    const sub = network === 'mainnet' ? 'explorer' : 'testnet'
    const link = `https://${sub}.qtum.org/address/${fromAddress}`
    const e = new Error(`Account <a href='${link}' target='_blank'>${fromAddress}</a> <br> You don't have sufficient Tokens to send`)
    e.name = 'ErrorMessage'
    throw e
  }
  const serializedTx = await wallet.generateTx(to, amount, fee)
  if (serializedTx) {
    const txId = await server.currentNode().sendRawTx(serializedTx)
    debugLog('txId =' + txId)
    return txId
  }
}

export default { transferQtumCoins, submitTransaction }
