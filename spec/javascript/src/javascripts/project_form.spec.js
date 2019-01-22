const $ = require('jquery')
const customBlockchainNetwork = require('src/javascripts/project_form')
let $select

describe('customBlockchainNetwork', () => {
  beforeEach(() => {
    document.body.innerHTML =
      "<select data-info='" +
      '{"bitcoin_mainnet":"Main Bitcoin Network","bitcoin_testnet":"Test Bitcoin Network","cardano_mainnet":"Main Cardano Network","cardano_testnet":"Test Cardano Network","qtum_mainnet":"Main QTUM Network","qtum_testnet":"Test QTUM Network"}' +
      "' name=\"project[blockchain_network]\">" +
      '</select>'
    $select = $("[name='project[blockchain_network]']")
  })

  it('with coin type of btc', () => {
    customBlockchainNetwork('btc')
    expect($select.find('option').length).toEqual(2)
    expect($select.find('option:eq(0)').attr('value')).toEqual('bitcoin_mainnet')
    expect($select.find('option:eq(1)').attr('value')).toEqual('bitcoin_testnet')
  })

  it('with coin type of qrc20', () => {
    customBlockchainNetwork('qrc20')
    expect($select.find('option').length).toEqual(2)
    expect($select.find('option:eq(0)').attr('value')).toEqual('qtum_mainnet')
    expect($select.find('option:eq(1)').attr('value')).toEqual('qtum_testnet')
  })

  it('with coin type of ada', () => {
    customBlockchainNetwork('ada')
    expect($select.find('option').length).toEqual(2)
    expect($select.find('option:eq(0)').attr('value')).toEqual('cardano_mainnet')
    expect($select.find('option:eq(1)').attr('value')).toEqual('cardano_testnet')
  })
})
