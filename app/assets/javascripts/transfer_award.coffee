window.alertMsg = (modal, msg) ->
  $(modal).find('.alert-msg').html(msg)
  $(modal).foundation('open')

window.transferAwardOnQtum = (award) -> # award in JSON
  if award.token.coin_type == 'qrc20'
    qrc20Qweb3.transferQrc20Tokens award
  else if award.token.coin_type == 'qtum'
    qtumLedger.transferQtumCoins award

transferAwardOnCardano = (award) -> # award in JSON
  cardanoTrezor.transferAdaCoins award

transferAwardOnBitcoin = (award) -> # award in JSON
  bitcoinTrezor.transferBtcCoins award

transferAwardOnEos = (award) -> # award in JSON
  eosScatter.transferEosCoins award

window.transferAward = (award) -> # award in JSON
  if award.token.coin_type == 'erc20' || award.token.coin_type == 'eth'
    transferAwardOnEthereum award
  else if award.token.coin_type == 'qrc20' || award.token.coin_type == 'qtum'
    transferAwardOnQtum award
  else if award.token.coin_type == 'ada'
    transferAwardOnCardano award
  else if award.token.coin_type == 'btc'
    transferAwardOnBitcoin award
  else if award.token.coin_type == 'eos'
    transferAwardOnEos award

$ ->
  $(document).on 'click', '.transfer-tokens-btn', ->
    award = JSON.parse $(this).attr('data-info')
    transferAward award
