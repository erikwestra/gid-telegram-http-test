'use strict'

// ##########################################################################
//
// telegramWrapper
//
//     This module provides a wrapper around Telegram, allowing me to test the
//     Telegram API calls from my test program.
//
// ##########################################################################

var Telegram = require('./telegram');

if(!global.Buffer) {
  global.Buffer = require('buffer/').Buffer;
}

// ##########################################################################
//
// Testing code for the low-level HTTP connection to the Telegram server.

var x_test = function() {

    var server = {
        host: "149.154.167.40",
        port: 443
    }

    var request_data = new Buffer("AAAAAAAAAABkf+txr8jKVxQAAAB4l0ZgjiEQQRji" +
                                  "PKwhgTZdxj719g==", "base64");

    var connection = new Telegram.MT.net.HttpConnection(server);
    connection.connect(function() {
        console.log("Connected");
        connection.write(request_data, function() {
            connection.read(function(error, response) {
                if (error) {
                    console.log("read error = " + JSON.stringify(error));
                } else {
                    console.log("read response = " + JSON.stringify(response));
                }
            });
        });
    });
}

// ==========================================================================
//
// test()
//
//     Test the Telegram interface.

var test = function() {

    var app = {
        lang: "en",
        id : 95301,
        hash: "ece00319f14e493b469c384b4dbe3dec",
        version: "0.0.1",
        deviceModel: "iPhone 6s",
        systemVersion: "iOS/9.1",
    }

    var data_centre = {
        host: "149.154.167.40",
        port: 443,
    }

    var client = Telegram.Link.createClient(app, data_centre,
                                            function(error) {
        if (error) {
            console.log("Unable to create client: " + JSON.stringify(error));
        } else {
            console.log("Creating auth key...");
            client.createAuthKey(function(auth) {
                console.log("Got Auth key: " + JSON.stringify(auth));
            });
        }
    });
}

// ==========================================================================
//
// Export our public interface:

module.exports = {
    test : test,
}
