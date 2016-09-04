'use strict'

const Env = require('../../config/Env')

const APP_ID = '64682'
const APP_HASH = 'd691dfefc9c339286b7417485001707c'

const APP_TITLE = 'My Global iD'
const APP_NAME_SHORT = 'myglobalid'

const Conf = {

  get env() {
    return Conf[Env.mode]
  },

  sandbox: {
    HOST: '149.154.167.40',
    PORT: 443,
    APP_ID,
    APP_HASH,
    APP_TITLE,
    APP_NAME_SHORT
  },

  live: {
    HOST: '149.154.167.50',
    PORT: 443,
    APP_ID,
    APP_HASH,
    APP_TITLE,
    APP_NAME_SHORT
  },


}

module.exports = Conf
