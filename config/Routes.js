const ROUTES = {
  default: {
    title: "Placeholder",
    navigation: false,
    lightTitlebar: false,
    get screen() { return require('../screens/Placeholder/Placeholder') }
  },
  intro: {
    title: "Introduction",
    navigation: false,
    lightTitlebar: false,
    get screen() { return require('../screens/Intro/Intro') }
  },
  features: {
    title: "Key Features",
    navigation: false,
    lightTitlebar: false,
    get screen() { return require('../screens/Intro/Features') }
  },
  profile: {
    title: "Profile",
    navigation: true,
    lightTitlebar: true,
    get screen() { return require('../screens/Profile/Profile') }
  },
  loginSignup: {
    title: "Login / Signup",
    navigation: false,
    lightTitlebar: false,
    get screen() { return require('../screens/LoginSignup/LoginSignup') }
  },
  chat: {
    title: "Chat with telegram",
    navigation: true,
    lightTitlebar: false,
    get screen() { return require('../screens/Chat/Chat') }
  },
  chatList: {
    title: "Conversations",
    navigation: true,
    lightTitlebar: false,
    get screen() { return require('../screens/Chat/ChatList') }
  },
  chatConversation: {
    title: "Chat with telegram",
    navigation: true,
    lightTitlebar: false,
    get screen() { return require('../screens/Chat/Conversation') }
  },
  chatContactList: {
    title: "Contacts",
    navigation: true,
    lightTitlebar: false,
    get screen() { return require('../screens/Chat/ContactList') }
  },
  // loginSetup: {
  //   title: "Login",
  //   navigation: false,
  //   lightTitlebar: false,
  //   get screen() { return require('../screens/LoginSignup/LoginSetup') }
  // },
  // emailSetup: {
  //   title: "Email Setup",
  //   navigation: false,
  //   lightTitlebar: false,
  //   get screen() { return require('../screens/LoginSignup/EmailSetup') }
  // },
  // emailConfirmation: {
  //   title: "Email Confirmation",
  //   navigation: false,
  //   lightTitlebar: false,
  //   get screen() { return require('../screens/LoginSignup/EmailConfirmation') }
  // },
  // emailSuccess: {
  //   title: "Email Success",
  //   navigation: false,
  //   lightTitlebar: false,
  //   get screen() { return require('../screens/LoginSignup/EmailSuccess') }
  // },
  phoneSetup: {
    title: "Phone Setup",
    navigation: false,
    lightTitlebar: false,
    get screen() { return require('../screens/LoginSignup/PhoneSetup') }
  },
  phoneVerification: {
    title: "Phone Verification",
    navigation: false,
    lightTitlebar: false,
    get screen() { return require('../screens/LoginSignup/PhoneVerification') }
  },
  passcodeSetup: {
    title: "Passcode Setup",
    navigation: false,
    lightTitlebar: false,
    get screen() { return require('../screens/LoginSignup/PasscodeSetup') }
  },
  passcodeSuccess: {
    title: "Passcode Success",
    navigation: false,
    lightTitlebar: false,
    get screen() { return require('../screens/LoginSignup/PasscodeSuccess') }
  },
  // usernameSetup: {
  //   title: "Username Setup",
  //   navigation: false,
  //   lightTitlebar: false,
  //   get screen() { return require('../screens/LoginSignup/UsernameSetup') }
  // },
  // usernameSuccess: {
  //   title: "Username Success",
  //   navigation: false,
  //   lightTitlebar: false,
  //   get screen() { return require('../screens/LoginSignup/UsernameSuccess') }
  // },
  accountDetails: {
    title: "Account Details",
    navigation: false,
    lightTitlebar: true,
    get screen() { return require('../screens/Activity/AccountDetails') }
  },
  summary: {
    title: "Summary",
    navigation: true,
    lightTitlebar: true,
    get screen() { return require('../screens/Summary/Summary') }
  },
  fundingsourcelist:{
    title: "Funding sources",
    navigation: true,
    lightTitlebar: true,
    get screen() { return require('../screens/Funding/SourceList') }
  },
  myBalances: {
    title: "My Balances",
    navigation: true,
    lightTitlebar: true,
    get screen() { return require('../screens/Balance/MyBalances') }
  },
  activityPage: {
    title: "Activity",
    navigation: true,
    lightTitlebar: true,
    get screen() { return require('../screens/Activity/ActivityPage') }
  },
  selectRecipient: {
    title: "Select Recipient",
    navigation: false,
    lightTitlebar: true,
    get screen() { return require('../screens/Contacts/SelectRecipient') }
  },
  sendPoints: {
    title: "Send Points",
    navigation: false,
    lightTitlebar: true,
    get screen() { return require('../screens/Balance/SendPoints') }
  },
  sendPointsSuccess: {
    title: "Send Points Success",
    navigation: false,
    lightTitlebar: true,
    get screen() { return require('../screens/Balance/SendPointsSuccess') }
  },
  profiles: {
    title: "Profiles",
    navigation: true,
    lightTitlebar: true,
    get screen() { return require('../screens/Contacts/Profiles') }
  },
  returnAuthentication: {
    title: "Return Authentication",
    navigation: false,
    lightTitlebar: false,
    get screen() { return require('../screens/LoginSignup/ReturnAuthentication') }
  },
  returnPasscode: {
    title: "Return Passcode",
    navigation: false,
    lightTitlebar: false,
    get screen() { return require('../screens/LoginSignup/ReturnPasscode') }
  },
  whatIs: {
    title: "What is global iD?",
    navigation: false,
    lightTitlebar: true,
    get screen() { return require('../screens/LoginSignup/WhatIs') }
  },
  weboauth: {
    title: "Connect your account",
    navigation: true,
    lightTitlebar: true,
    get screen() { return require('../screens/Weboauth/Weboauth') }
  },
  //telegramtest: {
  //  title: "Telegram Test",
  //  navigation: true,
  //  lightTitlebar: true,
  //  get screen() { return require('../screens/Telegram/TelegramTest') }
  //},
  gateHubLogin:{
    title: "Login with GateHub",
    navigation: false,
    lightTitlebar: false,
    get screen() { return require('../screens/LoginSignup/GateHubLogin') }
  },
  telegramSignin:{
    title: "Telegram login",
    navigation: false,
    lightTitlebar: false,
    get screen() { return require('../screens/LoginSignup/TelegramSignin') }
  }
}

module.exports = ROUTES
