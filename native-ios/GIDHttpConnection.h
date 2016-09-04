// GIDHttpConnection.h
//
// Header file for the GIDHttpConnection class.  This implements an HTTP
// connection using low-level TCP/IP sockets.

#import "GIDHttpSocket.h"

// ##########################################################################
//
// The following enumerated type defines the various states in which a
// GIDHttpConnection object can be in:

typedef enum {
    kConnectionStateReady,
    kConnectionStateSendingRequest,
    kConnectionStateWaitingForResponse,
    kConnectionStateClosed
} GIDHttpConnectionState;

// ==========================================================================
//
// The following type definition defines a block which is called when an HTTP
// request returned a successful response.  This block accepts a single
// parameter, 'response', which is an NSDictionary, and does not return
// anything.

typedef void (^GIDHttpConnectionRequestSuccess)(NSDictionary* response);

// ==========================================================================
//
// The following type definition defines a block which is called when an HTTP
// request fails with an error.  This block accepts a single parameter,
// 'error', which is an NSString, and does not return anything.

typedef void (^GIDHttpConnectionRequestError)(NSString* error);

// ##########################################################################

@interface GIDHttpConnection : NSObject <GIDHttpSocketDelegate>

// ==========================================================================
//
// initWithURL:
//
//     Initialise a new GIDHttpConnection object to access the given URL.

- (id) initWithURL:(NSURL*)url;

// ==========================================================================
//
// request:headers:contents:keep_alive:on_success:on_error:
//
//     Send an HTTP request to our server and port, and call the 'success'
//     block when we receive the response, or the 'error' block if an error
//     occurs.
//
//     If 'binary_request' is YES, the contents of the request will be treated
//     as base-64 encoded binary data.  If 'binary_response' is YES, the
//     success callback will be called with base-64 encoded response contents.

- (void) request:(NSString*)method
         headers:(NSArray*)headers
        contents:(NSString*)contents
  binary_request:(BOOL)binary_request
 binary_response:(BOOL)binary_response
      on_success:(GIDHttpConnectionRequestSuccess)success
        on_error:(GIDHttpConnectionRequestError)error;

// ==========================================================================
//
// close
//
//     Close our HTTP connection to the server.

- (void) close;

// ==========================================================================

@end

