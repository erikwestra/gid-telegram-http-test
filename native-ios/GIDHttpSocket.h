// GIDHttpSocket.h
//
// Header file for the GIDHttpSocket class.  This implements the low-level
// TCP/IP socket used to communicate with the remote server.

#import "GIDHttpSocketDelegate.h"

// ##########################################################################

@interface GIDHttpSocket : NSObject <NSStreamDelegate>

// ==========================================================================
//
// Our public properties:

@property (strong, nonatomic) id <GIDHttpSocketDelegate> delegate;

// ==========================================================================
//
// initWithServer:port:useSSL:
//
//     Initialise a new GIDHttpSocket object to access the given HTTP server
//     using the given TCP/IP port.
//
//     If 'useSSL' is YES, the socket will use Secure Sockets Layer (SSL).

- (id) initWithServer:(NSString*)server port:(int)port useSSL:(BOOL)useSSL;

// ==========================================================================
//
// send:
//
//     Send some data to the remote server.

- (void) send:(NSData*)data;

// ==========================================================================
//
// close
//
//     Close our socket.

- (void) close;

// ==========================================================================

@end

