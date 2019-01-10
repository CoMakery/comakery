function customBlockchainNetwork(coinType) {
  var prefix = ''
  switch(coinType) {
  case 'qrc20':
    prefix = 'qtum_'
    break;
  case 'ada':
    prefix = 'cardano_'
    break;
  }
  if(prefix != '') {
    $("[name='project[blockchain_network]']").children('option:not(:first)').remove()
    var data = JSON.parse($("[name='project[blockchain_network]']").attr('data-info'))
    $.each(data, (k,v) => {
      if(k.startsWith(prefix)) {
        $("[name='project[blockchain_network]']").append(new Option(v, k))
      }
    })
  }
}
