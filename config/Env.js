'use strict'

//const Deb = require('../lib/Debug')

let MODE = 'sandbox'

module.exports = {

  get mode() { return MODE },

  get isSandbox() {
    return MODE == 'sandbox'
  },

  get isLive() {
    return MODE == 'live'
  },

  setSandbox() {
    MODE = 'sandbox'
    //Deb.log('deb:Env:mode', MODE)
  },

  setLive() {
    MODE = 'live'
    //Deb.log('deb:Env:mode', MODE)
  }

}
