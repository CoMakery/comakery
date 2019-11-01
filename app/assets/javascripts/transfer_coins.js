window.transferEthers = function(award) { // award in JSON
  const toAddress = award.account.ethereum_wallet
  const amount = parseFloat(award.total_amount)

  if (toAddress && amount) {
    web3.eth.getBalance(web3.eth.coinbase, function(err, result) {
      if (result && (parseFloat(web3.fromWei(result.toNumber(), 'wei')) >= parseFloat(amount))) {
        web3.eth.sendTransaction({
          from: web3.eth.coinbase,
          to: toAddress,
          value: web3.toWei(amount, 'ether'),
          gasPrice: web3.toWei(1, 'gwei')
        }, function(err, tx) {
          if (tx) {
            $.post(`/projects/${award.project.id}/batches/${award.award_type.id}/tasks/${award.id}/update_transaction_address`, {tx})
            alert(`Successfully sent award to ${award.recipient_display_name}`)
            location.reload()
          } else if (err) {
            console.log(err)
            alert('Errors occurred, please click on REJECT button. Please transfer ethers on the blockchain with MetaMask on the awards page. Please make sure that gas fee is greater than 0 before clicking on CONFIRM button on MetaMask popup')
          }
        })
      } else {
        alert("You don't have sufficient Tokens to send")
      }
    })
  }
}
