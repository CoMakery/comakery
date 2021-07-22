/* eslint no-console:0 */
// This file is automatically compiled by Webpack, along with any other files
// present in this directory. You're encouraged to place your actual application logic in
// a relevant structure within app/javascript and only use these pack files to reference
// that code so it'll be compiled.
//
// To reference this file, add <%= javascript_pack_tag 'application' %>
// to the appropriate layout file

import * as Sentry from '@sentry/browser'
import { Integrations } from '@sentry/tracing'

Sentry.init({
  dsn: process.env.SENTRY_DSN,
  release: process.env.npm_package_version,
  integrations: [new Integrations.BrowserTracing()],

  // Set tracesSampleRate to 1.0 to capture 100%
  // of transactions for performance monitoring.
  // We recommend adjusting this value in production
  tracesSampleRate: 1.0
})

require('@rails/ujs').start()
import '@hotwired/turbo-rails'

// Support component names relative to this directory:
let componentRequireContext = require.context('components', true)
let ReactRailsUJS = require('react_ujs')
ReactRailsUJS.useContext(componentRequireContext)

import 'controllers'

require.context('../src/images', true)

import 'slick-carousel/slick/slick.css'
import 'slick-carousel/slick/slick-theme.css'
import 'animate.css'
import '@fortawesome/fontawesome-free/scss/fontawesome.scss'
import '@fortawesome/fontawesome-free/scss/regular.scss'
import '@fortawesome/fontawesome-free/scss/solid.scss'
import 'bootstrap/dist/js/bootstrap.bundle'

import '../src/application.scss'
import '../src/dist/css/upside-vendors.css'
import '../src/dist/js/upside.js'
import '../src/dist/css/tabler.css'
import '../src/dist/css/upside-override.css'

// TODO: enable when tabler migration is ready
// import '../src/dist/css/tabler.min.css'

// TODO: migrate libs to Yarn
import '../src/dist/libs/apexcharts/dist/apexcharts.min.js'
import '../src/dist/libs/countup.js/dist/countUp.js'
import '../src/dist/libs/nouislider/distribute/nouislider.min.js'

// TODO: enable wallet integration after testing and refactoring
//
// import '../src/wallets/bitcoin_trezor_script.js'
// import '../src/wallets/cardano_trezor_script.js'
// import '../src/wallets/eos_scatter_script.js'
// import '../src/wallets/qrc20_qweb3_script.js'
// import '../src/wallets/qtum_ledger_script.js'
// import '../src/wallets/tezos_trezor_script.js'

ReactRailsUJS.handleEvent('turbo:load', ReactRailsUJS.handleMount)
ReactRailsUJS.handleEvent('turbo:before-render', ReactRailsUJS.handleUnmount)
