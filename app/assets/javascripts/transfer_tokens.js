window.transferTokens = function(award) { // award in JSON
  const contractAddress = award.token.ethereum_contract_address
  const toAddress = award.account.ethereum_wallet
  const amount = award.amount_to_send

  if (contractAddress && toAddress && amount) {
    const contract = web3.eth.contract(abi) // see abi in abi.js
    const contractIns = contract.at(contractAddress)
    contractIns.balanceOf(web3.eth.coinbase, function(err, result) {
      if (result && (parseFloat(web3.fromWei(result.toNumber(), 'wei')) >= parseFloat(amount))) {
        contractIns.transfer(toAddress, web3.toWei(amount, 'wei'), { gasPrice: web3.toWei(1, 'gwei') }, function(err, tx) {
          if (tx) {
            $.post(`/projects/${award.project.id}/batches/${award.award_type.id}/tasks/${award.id}/update_transaction_address`, {tx})
            if ($('body.projects-show').length > 0) {
              $('.flash-msg').html(`Successfully sent award to ${award.recipient_display_name}`)
            }
          } else if (err) {
            console.log(err)
            alert( 'Errors occurred, please click on REJECT button. Please transfer ethers on the blockchain with MetaMask on the awards page. Please make sure that gas fee is greater than 0 before clicking on CONFIRM button on MetaMask popup')
          }
        })
      } else {
        alert( "You don't have sufficient Tokens to send")
      }
    })
  }
}
