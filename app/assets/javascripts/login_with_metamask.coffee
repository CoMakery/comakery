window.loginWithMetaMask = window.loginWithMetaMask || {}

loginWithMetaMask.handleAuthenticate = (ref) ->
  publicAddress = ref.publicAddress
  nonce = ref.nonce
  fetch('/api/accounts/auth',
    credentials: 'same-origin'
    body: JSON.stringify(
      public_address: publicAddress
      nonce: nonce)
    headers: 'Content-Type': 'application/json'
    method: 'POST').then((response) ->
      response.json()
    ).then (data) ->
      window.location = '/tasks' if data.success

loginWithMetaMask.handleSignup = (publicAddress, network) ->
  fetch('/api/accounts',
    body: JSON.stringify(public_address: publicAddress, network_id: network)
    headers: 'Content-Type': 'application/json'
    method: 'POST').then (response) ->
    response.json()
