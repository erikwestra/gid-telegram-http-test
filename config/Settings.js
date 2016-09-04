'use strict'

const Env = require('./Env')

const Settings = {
  LOCK_SCREEN_DELAY: 5 * 1000, // 5 secs before app locks after navigate away

  get env() {
    return Settings[Env.mode]
  },

  sandbox: {
    GCM_SENDER_ID: '814974002613'
	},

  live: {
    GCM_SENDER_ID: '814974002613'
  }

}

module.exports = Settings