// GIDHttpReactNativeModule.m
//
// Implementation for the GIDHttpReactNativeModule class.

#import "GIDHttpReactNativeModule.h"
#import "GIDHttpConnection.h"

// ##########################################################################
//
// Our private interface:

@interface GIDHttpReactNativeModule ()

@property (strong, atomic) NSMutableDictionary* connections;
@property (atomic, assign) int                  next_connection_id;

// ==========================================================================
//
// init
//
//     Initialise our module.

- (id) init;

// ==========================================================================
//
// new_connection_id
//
//     Create and return a new unique ID for a connection.

- (NSString*) new_connection_id;

// ==========================================================================
//
// methodQueue
//
//     Return the method queue to use for running our plugin.  We need to set
//     this to the main queue or else our socket won't receive delegate calls.

- (dispatch_queue_t) methodQueue;

// ==========================================================================

@end

// ##########################################################################

@implementation GIDHttpReactNativeModule

RCT_EXPORT_MODULE();

// ==========================================================================
// ==                                                                      ==
// ==                   I N T E R N A L   M E T H O D S                    ==
// ==                                                                      ==
// ==========================================================================

- (id) init {

    if (self = [super init]) {
        self.connections        = [[NSMutableDictionary alloc] init];
        self.next_connection_id = 1;
        return self;
    } else {
        return nil;
    }
}

// ==========================================================================

- (NSString*) new_connection_id {

    int connection_id = self.next_connection_id;
    self.next_connection_id = self.next_connection_id + 1;

    return [NSString stringWithFormat:@"CONNECTION-%d", connection_id];
}

// ==========================================================================

- (dispatch_queue_t) methodQueue {

    return dispatch_get_main_queue();
}

// ==========================================================================
// ==                                                                      ==
// ==                     P U B L I C   M E T H O D S                      ==
// ==                                                                      ==
// ==========================================================================
//
// create(url)
//
//     Create a new GIDHttpConnection.  Returns [error, connection_id], where
//     'error' will be a string describing what went wrong (if anything), and
//     'connection_id' is the unique ID for this connection if the connection
//     was successfully created.

RCT_EXPORT_METHOD(create:(NSString*)url
                callback:(RCTResponseSenderBlock)callback) {

    NSURL* url_object = [NSURL URLWithString:url];
    if (url_object == nil) {
        callback(@[@"INVALID URL", [NSNull null]]);
        return;
    }

    NSString* connection_id = [self new_connection_id];

    GIDHttpConnection* connection = [[GIDHttpConnection alloc]
                                     initWithURL:[NSURL URLWithString:url]];

    self.connections[connection_id] = connection;

    callback(@[[NSNull null], connection_id]);
}

// ==========================================================================
//
// destroy(connection_id)
//
//     Destroy a GIDHttpConnection.  Returns true if the connection was closed.

RCT_EXPORT_METHOD(destroy:(NSString*)connection_id
                 callback:(RCTResponseSenderBlock)callback) {

    GIDHttpConnection* connection = self.connections[connection_id];

    if (connection == nil) {
       callback(@[[NSNumber numberWithBool:NO]]);
       return;
    }

    [connection close];
    [self.connections removeObjectForKey:connection_id];

    callback(@[[NSNumber numberWithBool:YES]]);
}

// ==========================================================================
//
// request(connection_id, method, headers, contents, binary_request,
//         binary_response)
//
//     Send an HTTP request to the remote server, and wait for a response.
//
//     Returns [error, response], where 'error' will be a string describing
//     what went wrong, or nil if there is no error, and 'response' will be an
//     object with the following fields:
//
//         'status'
//
//             The numeric status code returned by the server.
//
//         'headers'
//
//             An array of [header, value] arrays defining the response headers
//             returned by the server.
//
//         'contents'
//
//             The contents of the response, if any, as a string.  If the
//             'binary_response' parameter is set to true, the contents will be
//             base-64 encoded, allowing binary data to be returned.

RCT_EXPORT_METHOD(request:(NSString*)connection_id
                   method:(NSString*)method
                  headers:(NSArray*)headers
                 contents:(NSString*)contents
           binary_request:(nonnull NSNumber*)binary_request
          binary_response:(nonnull NSNumber*)binary_response
                 callback:(RCTResponseSenderBlock)callback) {

    GIDHttpConnection* connection = self.connections[connection_id];

    if (connection == nil) {
        callback(@[@"INVALID CONNECTION ID", [NSNull null]]);
        return;
    }

    // Define our "success" block.  This gets called when the HTTP connection
    // returns a successful response; we pass this response back to our React
    // Native callback function.

    GIDHttpConnectionRequestSuccess success = ^void(NSDictionary* response) {
        callback(@[[NSNull null], response]);
    };

    // Define our "error" block.  This gets called when an error occurs; we
    // pass this error back to our Reach native callback function.

    GIDHttpConnectionRequestError error = ^void(NSString* error) {
        callback(@[error, [NSNull null]]);
    };

    // Finally, pass the request on to our connection object.  This will call
    // our callback function once the request has been processed.

    [connection request:method
                headers:headers
               contents:contents
         binary_request:[binary_request boolValue]
        binary_response:[binary_response boolValue]
             on_success:success
               on_error:error];
}

// ==========================================================================

@end
