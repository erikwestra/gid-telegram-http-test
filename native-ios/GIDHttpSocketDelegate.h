// GIDHttpSocketDelegate.h
//
// This formal protocol defines the methods which must be provided by the
// GIDHttpSocket delegate.

// ##########################################################################

@class GIDHttpSocket;

// ##########################################################################

@protocol GIDHttpSocketDelegate

// ==========================================================================
//
// socket:sentData:
//
//     Respond to some data being sent by our TCP/IP socket.

- (void) socket:(GIDHttpSocket*)socket sentData:(NSData*)data;

// ==========================================================================
//
// socket:receivedData:
//
//     Respond to some data being received by our TCP/IP socket.

- (void) socket:(GIDHttpSocket*)socket receivedData:(NSData*)data;

// ==========================================================================
//
// socket:hadError:
//
//     Respond to an error occuring in our TCP/IP socket.

- (void) socket:(GIDHttpSocket*)socket hadError:(NSError*)error;

// ==========================================================================
//
// socketwasClosed:
//
//     Respond to our socket being closed.

- (void) socketWasClosed:(GIDHttpSocket*)socket;

// ==========================================================================

@end

