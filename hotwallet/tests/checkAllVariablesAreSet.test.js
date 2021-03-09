const hwUtils = require('../lib/hotwalletUtils')

test('all ENVs are set', async () => {
  const envs = {
    projectId: "1",
    projectApiKey: "project_api_key",
    comakeryServerUrl: "http://cmk.server",
    purestakeApi: "purestake_api_key",
    redisUrl: "redis://localhost:6379/0",
    checkForNewTransactionsDelay: 30,
    optInApp: 13997710,
    blockchainNetwork: 'algorand_test'
  }
  expect(hwUtils.checkAllVariablesAreSet(envs)).toBe(true)
})

test('projectId is null', async () => {
  const envs = {
    projectId: null,
    projectApiKey: "project_api_key",
    comakeryServerUrl: "http://cmk.server",
    purestakeApi: "purestake_api_key",
    redisUrl: "redis://localhost:6379/0",
    checkForNewTransactionsDelay: 30,
    optInApp: 13997710,
    blockchainNetwork: 'algorand_test'
  }
  expect(hwUtils.checkAllVariablesAreSet(envs)).toBe(false)
})

test('projectId is undefined', async () => {
  const envs = {
    projectApiKey: "project_api_key",
    comakeryServerUrl: "http://cmk.server",
    purestakeApi: "purestake_api_key",
    redisUrl: "redis://localhost:6379/0",
    checkForNewTransactionsDelay: 30,
    optInApp: 13997710,
    blockchainNetwork: 'algorand_test'
  }
  expect(hwUtils.checkAllVariablesAreSet(envs)).toBe(false)
})

test('projectId is undefined', async () => {
  const envs = {
    projectId: undefined,
    projectApiKey: "project_api_key",
    comakeryServerUrl: "http://cmk.server",
    purestakeApi: "purestake_api_key",
    redisUrl: "redis://localhost:6379/0",
    checkForNewTransactionsDelay: 30,
    optInApp: 13997710,
    blockchainNetwork: 'algorand_test'
  }
  expect(hwUtils.checkAllVariablesAreSet(envs)).toBe(false)
})

test('projectApiKey is null', async () => {
  const envs = {
    projectId: "1",
    projectApiKey: null,
    comakeryServerUrl: "http://cmk.server",
    purestakeApi: "purestake_api_key",
    redisUrl: "redis://localhost:6379/0",
    checkForNewTransactionsDelay: 30,
    optInApp: 13997710,
    blockchainNetwork: 'algorand_test'
  }
  expect(hwUtils.checkAllVariablesAreSet(envs)).toBe(false)
})

test('comakeryServerUrl is null', async () => {
  const envs = {
    projectId: "1",
    projectApiKey: "project_api_key",
    comakeryServerUrl: null,
    purestakeApi: "purestake_api_key",
    redisUrl: "redis://localhost:6379/0",
    checkForNewTransactionsDelay: 30,
    optInApp: 13997710,
    blockchainNetwork: 'algorand_test'
  }
  expect(hwUtils.checkAllVariablesAreSet(envs)).toBe(false)
})

test('purestakeApi is null', async () => {
  const envs = {
    projectId: "1",
    projectApiKey: "project_api_key",
    comakeryServerUrl: "http://cmk.server",
    purestakeApi: null,
    redisUrl: "redis://localhost:6379/0",
    checkForNewTransactionsDelay: 30,
    optInApp: 13997710,
    blockchainNetwork: 'algorand_test'
  }
  expect(hwUtils.checkAllVariablesAreSet(envs)).toBe(false)
})

test('redisUrl is null', async () => {
  const envs = {
    projectId: "1",
    projectApiKey: "project_api_key",
    comakeryServerUrl: "http://cmk.server",
    purestakeApi: "purestake_api_key",
    redisUrl: null,
    checkForNewTransactionsDelay: 30,
    optInApp: 13997710,
    blockchainNetwork: 'algorand_test'
  }
  expect(hwUtils.checkAllVariablesAreSet(envs)).toBe(false)
})

test('checkForNewTransactionsDelay is null', async () => {
  const envs = {
    projectId: "1",
    projectApiKey: "project_api_key",
    comakeryServerUrl: "http://cmk.server",
    purestakeApi: "purestake_api_key",
    redisUrl: "redis://localhost:6379/0",
    checkForNewTransactionsDelay: null,
    optInApp: 13997710,
    blockchainNetwork: 'algorand_test'
  }
  expect(hwUtils.checkAllVariablesAreSet(envs)).toBe(false)
})

test('optInApp is null', async () => {
  const envs = {
    projectId: "1",
    projectApiKey: "project_api_key",
    comakeryServerUrl: "http://cmk.server",
    purestakeApi: "purestake_api_key",
    redisUrl: "redis://localhost:6379/0",
    checkForNewTransactionsDelay: 30,
    optInApp: null,
    blockchainNetwork: 'algorand_test'
  }
  expect(hwUtils.checkAllVariablesAreSet(envs)).toBe(false)
})


test('blockchainNetwork is null', async () => {
  const envs = {
    projectId: "1",
    projectApiKey: "project_api_key",
    comakeryServerUrl: "http://cmk.server",
    purestakeApi: "purestake_api_key",
    redisUrl: "redis://localhost:6379/0",
    checkForNewTransactionsDelay: 30,
    optInApp: 13997710,
    blockchainNetwork: null
  }
  expect(hwUtils.checkAllVariablesAreSet(envs)).toBe(false)
})
