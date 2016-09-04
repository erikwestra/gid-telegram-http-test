// GIDHttpSocket.m
//
// Implementation for the GIDHttpSocket class.

#import "GIDHttpSocket.h"

// ##########################################################################
//
// Should we write debugging messages to the console?

#define DEBUG_MODE 0

// ##########################################################################
//
// Our private interface:

@interface GIDHttpSocket ()

@property (strong, nonatomic) NSString*       _server;
@property (assign, nonatomic) int             _port;
@property (assign, nonatomic) BOOL            _useSSL;
@property (assign, nonatomic) BOOL            _connected;
@property (strong, nonatomic) NSInputStream*  _input_stream;
@property (strong, nonatomic) NSOutputStream* _output_stream;
@property (strong, nonatomic) NSMutableData*  _data_to_send;
@property (assign, nonatomic) int             _num_bytes_sent;
@property (assign, nonatomic) BOOL            _send_bytes_on_event;

// ==========================================================================
//
// open_connection
//
//     Open a TCP/IP connection to the server.
//
//     We set self.input_stream and self.output_stream to the streams used to
//     communicate with the remote server.

- (void) open_connection;

// ==========================================================================
//
// on_data_received
//
//     Respond to some data being received from our input stream.

- (void) on_data_received;

// ==========================================================================
//
// has_data_to_send
//
//     Return YES if we have data waiting to be sent, else NO.

- (BOOL) has_data_to_send;

// ==========================================================================
//
// send_data
//
//     Send the next chunk of data to the output stream.

- (void) send_data;

// ==========================================================================
//
// on_input_stream_error
//
//     Respond to an error occurring on our input stream.

- (void) on_input_stream_error;

// ==========================================================================
//
// on_input_stream_closing
//
//     Respond to our input stream being closed by the remote server.

- (void) on_input_stream_closing;

// ==========================================================================
//
// on_output_stream_closing
//
//     Respond to our output stream being closed by the remote server.

- (void) on_output_stream_closing;

// ==========================================================================
//
// on_output_stream_error
//
//     Respond to an error occurring on our output stream.

- (void) on_output_stream_error;

// ==========================================================================

@end

// ##########################################################################

@implementation GIDHttpSocket

// ==========================================================================
// ==                                                                      ==
// ==                     P U B L I C   M E T H O D S                      ==
// ==                                                                      ==
// ==========================================================================

- (id) initWithServer:(NSString*)server port:(int)port useSSL:(BOOL)useSSL {

    if (self = [super init]) {
        self.delegate             = nil;
        self._server              = server;
        self._port                = port;
        self._useSSL              = useSSL;
        self._connected           = NO;
        self._input_stream        = nil;
        self._output_stream       = nil;
        self._data_to_send        = [[NSMutableData alloc] init];
        self._num_bytes_sent      = 0;
        self._send_bytes_on_event = YES;
    }

    return self;
}

// ==========================================================================

- (void) send:(NSData*)data {

#if DEBUG_MODE
    NSLog(@"Socket: SENDING: %@", data);
#endif

    [self._data_to_send appendData:data];

    if (!self._connected) {
        [self open_connection];
    }

    if (self._send_bytes_on_event) {
        // Nothing more to do...we wait for the next
        // NSStreamEventHasSpaceAvailable event and send the next chunk of data
        // then.
    } else {
        // Pre-emptively send the next chunk of data, and then continue sending
        // more chunks as events are received.
        [self send_data];
        self._send_bytes_on_event = YES;
    }
}

// ==========================================================================

- (void) close {

#if DEBUG_MODE
    NSLog(@"Socket: CLOSING");
#endif

    if (self._input_stream != nil) {
        [self._input_stream close];
        [self._input_stream removeFromRunLoop:[NSRunLoop currentRunLoop]
                                      forMode:NSDefaultRunLoopMode];
        self._input_stream = nil;
    }

    if (self._output_stream != nil) {
        [self._output_stream close];
        [self._output_stream removeFromRunLoop:[NSRunLoop currentRunLoop]
                                       forMode:NSDefaultRunLoopMode];
        self._output_stream = nil;
    }

    self._connected = NO;
}

// ==========================================================================
// ==                                                                      ==
// ==           N S S T R E A M D E L E G A T E   M E T H O D S            ==
// ==                                                                      ==
// ==========================================================================
//
// stream:handleEvent:
//
//     Respond to a stream event.  Note that this method is called for both
//     input and output stream events.
//
//     We simply detect which stream we are dealing with, and which event type,
//     and call the appropriate event handler function to do all the work.

- (void) stream:(NSStream*)stream handleEvent:(NSStreamEvent)event {

#if DEBUG_MODE
    NSLog(@"Socket: got event: %ld", (long)event);
#endif

    if (stream == self._input_stream) {
        if (event == NSStreamEventHasBytesAvailable) {
            [self on_data_received];
        } else if (event == NSStreamEventErrorOccurred) {
            [self on_input_stream_error];
        } else if (event == NSStreamEventEndEncountered) {
            [self on_input_stream_closing];
        }
    } else if (stream == self._output_stream) {
        if (event == NSStreamEventHasSpaceAvailable) {
            if ([self has_data_to_send]) {
                [self send_data];
            } else {
                // We have no more data to send -> when we do have more data to
                // send, send it pre-emptively rather than waiting for the
                // event.  We have to do this because iOS stops sending us
                // these events if we don't send any data through.
                self._send_bytes_on_event = NO;
            }
        } else if (event == NSStreamEventEndEncountered) {
            [self on_output_stream_closing];
        } else if (event == NSStreamEventErrorOccurred) {
            [self on_output_stream_error];
        }
    }
}

// ==========================================================================
// ==                                                                      ==
// ==                   I N T E R N A L   M E T H O D S                    ==
// ==                                                                      ==
// ==========================================================================

- (void) open_connection {

#if DEBUG_MODE
    NSLog(@"Socket: open_connection");
#endif

    CFReadStreamRef  readStream;
    CFWriteStreamRef writeStream;
    CFStringRef      server = (__bridge CFStringRef)self._server;
    int              port   = self._port;

    CFStreamCreatePairWithSocketToHost(NULL, server, port,
                                       &readStream, &writeStream);

    self._input_stream = (__bridge_transfer NSInputStream*)readStream;
    self._output_stream = (__bridge_transfer NSOutputStream*)writeStream;

    if (self._useSSL) {
        [self._input_stream setProperty:NSStreamSocketSecurityLevelNegotiatedSSL
                                forKey:NSStreamSocketSecurityLevelKey];
        [self._output_stream setProperty:NSStreamSocketSecurityLevelNegotiatedSSL
                                  forKey:NSStreamSocketSecurityLevelKey];
    }

    [self._input_stream setDelegate:self];
    [self._output_stream setDelegate:self];

    [self._input_stream scheduleInRunLoop:[NSRunLoop currentRunLoop]
                                 forMode:NSDefaultRunLoopMode];
    [self._output_stream scheduleInRunLoop:[NSRunLoop currentRunLoop]
                                  forMode:NSDefaultRunLoopMode];

    [self._input_stream open];
    [self._output_stream open];

    self._connected = YES;
}

// ==========================================================================

- (void) on_data_received {

#if DEBUG_MODE
    NSLog(@"Socket: on_data_received");
#endif

    uint8_t buffer[1024];
    int bytes_read;

    while ([self._input_stream hasBytesAvailable]) {
        bytes_read = (int)[self._input_stream read:buffer maxLength:1024];

        if (bytes_read > 0) {
            NSMutableData* data = [[NSMutableData alloc] init];
            [data appendBytes:(const void*)buffer length:bytes_read];
            [self.delegate socket:self receivedData:data];
        }
    }
}

// ==========================================================================

- (BOOL) has_data_to_send {

    if (self._num_bytes_sent == [self._data_to_send length]) {
        return NO;
    } else {
        return YES;
    }
}

// ==========================================================================

- (void) send_data {

#if DEBUG_MODE
    NSLog(@"Socket: in send_data");
#endif

    uint8_t* src_ptr = (uint8_t*)[self._data_to_send mutableBytes];
    src_ptr = src_ptr + self._num_bytes_sent;

    unsigned int num_bytes_left;
    num_bytes_left = (unsigned int)[self._data_to_send length]
                   - self._num_bytes_sent;

    unsigned int chunk_size;
    if (num_bytes_left > 1024) {
        chunk_size = 1024;
    } else {
        chunk_size = num_bytes_left;
    }

    uint8_t buffer[chunk_size];
    memcpy(buffer, src_ptr, chunk_size);

    chunk_size = (unsigned int)[self._output_stream write:(const uint8_t*)buffer
                                                maxLength:chunk_size];

    self._num_bytes_sent = self._num_bytes_sent + chunk_size;

    if (self._num_bytes_sent == [self._data_to_send length]) {
        // We've sent all the data -> tell our delegate that we've sent the
        // data and reset our output buffer.
        [self.delegate socket:self sentData:self._data_to_send];
        [self._data_to_send setLength:0];
        self._num_bytes_sent = 0;
    }
}

// ==========================================================================

- (void) on_input_stream_error {

#if DEBUG_MODE
    NSLog(@"Socket: on_input_stream_error");
#endif

    NSError* error = [self._input_stream streamError];
    [self.delegate socket:self hadError:error];

    [self._input_stream close];
    self._input_stream = nil;

    if (self._output_stream == nil) {
        [self.delegate socketWasClosed:self];
        self._connected = NO;
    }
}

// ==========================================================================

- (void) on_input_stream_closing {

#if DEBUG_MODE
    NSLog(@"Socket: on_input_stream_closing");
#endif

    [self._input_stream close];
    [self._input_stream removeFromRunLoop:[NSRunLoop currentRunLoop]
                                  forMode:NSDefaultRunLoopMode];
    self._input_stream = nil;

    if (self._output_stream == nil) {
        [self.delegate socketWasClosed:self];
        self._connected = NO;
    }
}

// ==========================================================================

- (void) on_output_stream_closing {

#if DEBUG_MODE
    NSLog(@"Socket: on_output_stream_closing");
#endif

    [self._output_stream close];
    [self._output_stream removeFromRunLoop:[NSRunLoop currentRunLoop]
                                   forMode:NSDefaultRunLoopMode];
    self._output_stream = nil;

    if (self._input_stream == nil) {
        [self.delegate socketWasClosed:self];
        self._connected = NO;
    }
}

// ==========================================================================

- (void) on_output_stream_error {

#if DEBUG_MODE
    NSLog(@"Socket: on_output_stream_error");
#endif

    NSError* error = [self._output_stream streamError];
    [self.delegate socket:self hadError:error];

    [self._output_stream close];
    self._output_stream = nil;

    if (self._input_stream == nil) {
        [self.delegate socketWasClosed:self];
        self._connected = NO;
    }
}

// ==========================================================================

@end
