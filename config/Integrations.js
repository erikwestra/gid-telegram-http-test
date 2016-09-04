module.exports = [
  // {
  //   name: "Gatehub",
  //   icon: "",
  //   enabled: true
  // },
  // {
  //   name: "Shift",
  //   icon: "",
  //   enabled: true,
  // },
  {
    name: "Dwolla",
    icon: "",
    enabled: true,
    connectViaLinking: true,
    get lib() { return require('../lib/dwolla').Dwolla }
  },
  //{
  //   name: "Bitstamp",
  //   icon: "",

  // },{
  //   name: "Coinbase",
  //   icon: "",

  // },{
  //   name: "Plaid",
  //   icon: "",
  // }
]