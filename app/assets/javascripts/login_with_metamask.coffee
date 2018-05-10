window.loginWithMetaMask = {}

loginWithMetaMask.handleAuthenticate = (ref) ->
  publicAddress = ref.publicAddress
  signature = ref.signature
  fetch('/api/accounts/auth',
    credentials: 'same-origin'
    body: JSON.stringify(
      public_address: publicAddress
      signature: signature)
    headers: 'Content-Type': 'application/json'
    method: 'POST').then((response) ->
      response.json()
    ).then (data) ->
      window.location = '/' if data.success

loginWithMetaMask.handleSignup = (publicAddress, network) ->
  fetch('/api/accounts',
    body: JSON.stringify(public_address: publicAddress, network_id: network)
    headers: 'Content-Type': 'application/json'
    method: 'POST').then (response) ->
    response.json()

loginWithMetaMask.handleSignMessage = (ref) ->
  publicAddress = ref.public_address
  nonce = ref.nonce
  new Promise((resolve, reject) ->
    web3.personal.sign web3.fromUtf8('Comakery, I am signing my nonce: ' + nonce), publicAddress, (err, signature) ->
      if err
        return reject(err)
      resolve
        publicAddress: publicAddress
        signature: signature
)

loginWithMetaMask.handleClick = ->
  $target = $('.auth-button.signin-with-metamask')
  if !window.web3
    window.alert 'Please install MetaMask first.'
    return
  if !web3
    web3 = new Web3(window.web3.currentProvider)
  if !web3.eth.coinbase
    window.alert 'Please activate MetaMask first.'
    return
  publicAddress = web3.eth.coinbase.toLowerCase()
  $target.find('span').text('Loading ...')
  fetch('/api/accounts/find_by_public_address?public_address=' + publicAddress).then((response) ->
    response.json()
  ).then((data) ->
    if data.public_address then data else loginWithMetaMask.handleSignup(publicAddress, web3.version.network)
  ).then(loginWithMetaMask.handleSignMessage).then(loginWithMetaMask.handleAuthenticate).catch (err) ->
    $target.find('span').text('Sign in with MetaMask')
    return
  return
