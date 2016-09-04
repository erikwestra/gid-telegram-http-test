// GIDTelegramHTTPTest
//
// This sample React Native application attempts to use the GIDHttpConnection
// plugin for React Native to communicate with Telegram.
//
// ##########################################################################

import React, { Component } from 'react';

import {
  AppRegistry,
  StyleSheet,
  TouchableHighlight,
  Text,
  View
} from 'react-native';

import { NativeModules } from 'react-native';

var TelegramWrapper = require('./lib/telegramWrapper.js');

// ##########################################################################
//
// test_connection()
//
//     This function does all the real work.  It is called when the user taps
//     on our "Test Telegram Connection" button.

var test_connection = function() {
    TelegramWrapper.test();
}

var x_test_connection = function() {

    var GIDHttpConnection = NativeModules.GIDHttpReactNativeModule;

    GIDHttpConnection.create("http://www.httpbin.org",
        function(error, connection_id) {
            if (error != null) {
                alert(error);
                return;
            }

            var headers = [["Content-Length", 0],
                           ["Host", "httpbin.org"]];
            GIDHttpConnection.request(connection_id, "GET", headers,
                                      "", false, false,
                function(error, response) {
                    console.log("error = " + JSON.stringify(error));
                    console.log("response = " + JSON.stringify(response));

                    GIDHttpConnection.destroy(connection_id,
                        function(destroyed) {
                            console.log("Destroyed: ", destroyed);
                        }
                    );
                }
            );
        }
    );
}

// ##########################################################################
//
// The rest of this file contains the user interface for the app.  There's
// nothing interesting here.

class GIDTelegramHTTPTest extends Component {
  render() {
    return (
      <View style={styles.container}>
        <TouchableHighlight style={styles.button}
                            onPress={test_connection}>
            <Text style={styles.bold}>
                Test Telegram Connection
            </Text>
        </TouchableHighlight>
      </View>
    );
  }
}

const styles = StyleSheet.create({
    container: {
        flex: 1,
        justifyContent: 'center',
        alignItems: 'center',
        backgroundColor: '#F5FCFF',
      },
    button: {
        borderWidth: 1,
        borderColor: '#404080',
        padding: 20,
        backgroundColor: '#80a0ff',
    },
    bold: {
        fontWeight: 'bold',
    },
});

AppRegistry.registerComponent('GIDTelegramHTTPTest', () => GIDTelegramHTTPTest);

