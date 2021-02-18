require("dotenv").config()
const redis = require("redis")
const hwUtils = require("./lib/hotwalletUtils")

const envs = {
  projectId: process.env.PROJECT_ID,
  projectApiKey: process.env.PROJECT_API_KEY,
  comakeryServerUrl: process.env.COMAKERY_SERVER_URL,
  purestakeApi: process.env.PURESTAKE_API,
  redisUrl: process.env.REDIS_URL,
  checkForNewTransactionsDelay: parseInt(process.env.CHECK_FOR_NEW_TRANSACTIONS_DELAY)
}

const redisClient = redis.createClient(envs.redisUrl)

async function initialize() {
  if (!hwUtils.checkAllVariablesAreSet(envs)) { return "Some ENV vars was not set" }

  hwUtils.setRedisErrorHandler(redisClient)
  await hwUtils.hotWalletInitialization(envs, redisClient)

  return true
}

(async () => {
  // await hwUtils.deleteCurrentKey(envs, redisClient)
  await initialize()
  hwUtils.runServer(envs, redisClient)

  // hwUtils.optInToApp('algorand_testnet', envs, redisClient)
})();
