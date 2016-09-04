// http-connection.js
//
//     This module is a plug-in replacement for the http-connection object
//     provided by the MTProto library.  It uses the GIDHttpConnection native
//     module to implement HTTP communications.
//
// ==========================================================================
//
//     HttpConnection class
//
// This class provides a HTTP transport to communicate with `Telegram` using
// `MTProto` protocol
//
// ##########################################################################

var URL = require('url-parse');

import { NativeModules } from 'react-native';
var GIDHttpConnection = NativeModules.GIDHttpReactNativeModule;

if(!global.Buffer) {
  global.Buffer = require('buffer/').Buffer;
}

// ##########################################################################
//
// HttpConnection(options)
//
//     Constructor for the HttpConnection class.  'options' should be an object
//     with the following fields:
//
//         'protocol'
//
//             The HTTP protocol to use.  Defaults to "http:" if not given.
//
//         'host'
//
//             The HTTP server to connect to.  Defaults to "localhost".
//
//         'port'
//
//             The TCP/IP port to connect to.  Defaults to 80.
//
//         'path'
//
//             The relative path to include in the URL.  Defaults to "/apiw1".

function HttpConnection(options) {

    var protocol;
    if (options.protocol) {
        protocol = options.protocol;
    } else {
        protocol = "http:";
    }

    var host;
    if (options.host) {
        host = options.host;
    } else {
        host = "localhost";
    }

    var port;
    if (options.port) {
        port = options.port.toString();
    } else {
        port = "80";
    }

    var path;
    if (options.path) {
        path = options.path;
    } else {
        path = "/apiw1";
    }

    var url = protocol + "//" + host + ":" + port + path;

    this._id            = Math.floor(Math.random() * 100000);
    this._url           = url;
    this._host          = host;
    this._connection_id = null;
    this._write_buffers = [];
}

// ==========================================================================
//
// connection.connect(callback)
//
//     Connect to the remote server.
//
//     'callback' is a function to call (with no parameters) once the
//     connection has been established.

HttpConnection.prototype.connect = function(callback) {

    self = this;

    GIDHttpConnection.create(this._url, function(error, connection_id) {
        if (error != null) {
            console.log("HttpConnection.connect() failed: " + error);
            if (callback) {
                callback(); // Unfortunately, there's no way of returning an
                            // error back to Telegram.
            }
        } else {
            self._connection_id = connection_id;
            if (callback) {
                callback();
            }
        }
    });
};

// ==========================================================================
//
// connection.isConnected()
//
//     Return true if and only if we are currently connected to the remote
//     server.

HttpConnection.prototype.isConnected = function() {

    if (this._connection_id != null) {
        return true;
    } else {
        return false;
    }
};

// ==========================================================================
//
// connection.write(buffer, callback)
//
//     Attempt to write the given data to the remote server.
//
//     'buffer' will be a Buffer object containing the data to send to the
//     server.
//
//     The given callback function will be called, with no parameters, once the
//     data has been written.
//
//     Note that this function cheats, storing the buffer and sending the
//     accumulated buffers all at once when the read() method is called.

HttpConnection.prototype.write = function(buffer, callback) {

    this._write_buffers.push(buffer);
    if (callback) {
        setTimeout(callback, 0);
    }
};

// ==========================================================================
//
// connection.read(callback)
//
//     Attempt to read a response from the remote server.
//
//     If the server returned a response, callback(null, response) will be
//     called, where 'response' is the contents of the response as a Buffer
//     object.  If an error occurs, callback(error, null) will be called, where
//     'error' is the returned error.
//
//     Note that, like the original HttpConnection class, we buffer the calls
//     to write(), and then issue the entire HTTP request in the read() method,
//     passing the response to the callback function once the request has been
//     processed.

HttpConnection.prototype.read = function(callback) {

    var data = Buffer.concat(this._write_buffers);
    this._write_buffers = [];

    var encoded_data = data.toString('base64');

    var method;
    if (encoded_data.length > 0) {
        method = "POST";
    } else {
        method = "GET";
    }

    var headers = [];
    headers.push(["Content-Length", data.length.toString()]);
    headers.push(["Connection",     "keep-alive"]);
    headers.push(["Host",           this._host]);

    GIDHttpConnection.request(this._connection_id, method, headers,
                              encoded_data, true, true,
                              function(error, response) {
        if (error) {
            if (callback) {
                callback(error, null);
            }
        } else {
            var buffer = new Buffer(response.contents, "base64");
            if (response.status == 200) {
                if (callback) {
                    callback(null, buffer);
                }
            } else {
                // Treat a non-200 response as an error.
                if (callback) {
                    callback(buffer, null);
                }
            }
        }
    });
};

// ==========================================================================
//
// connection.close(callback)
//
//     Close our connection to the remote server.
//
//     The given callback function will be called, with no parameters, once the
//     connection has been closed.

HttpConnection.prototype.close = function (callback) {

    GIDHttpConnection.destroy(this._connection_id);
    this._connection_id = null;
};

// ##########################################################################

// Export our class:

module.exports = exports = HttpConnection;
