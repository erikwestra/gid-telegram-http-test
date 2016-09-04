// GIDHttpConnection.m
//
// Implementation for the GIDHttpConnection class.

#import "GIDHttpConnection.h"

// ##########################################################################
//
// Should we write debugging messages to the console?

#define DEBUG_MODE 0

// ##########################################################################
//
// Our private interface:

@interface GIDHttpConnection ()

@property (assign, nonatomic) GIDHttpConnectionState          _state;
@property (strong, nonatomic) NSURL*                          _url;
@property (strong, nonatomic) GIDHttpSocket*                  _socket;
@property (copy,   nonatomic) GIDHttpConnectionRequestSuccess _success;
@property (copy,   nonatomic) GIDHttpConnectionRequestError   _error;
@property (strong, nonatomic) NSString*                       _cur_method;
@property (strong, nonatomic) NSMutableData*                  _response;
@property (assign, nonatomic) BOOL                            _binary_response;

// ==========================================================================
//
// setState:
//
//     Set our socket to be in the given state.
//
//     We also output the change in state to the console if DEBUG_MODE is 1.

- (void) setState:(GIDHttpConnectionState)state;

// ==========================================================================
//
// string:equals:
//
//     Return YES if and only if 'string1' and 'string2' are equal, using a
//     case-insensitive comparison.

- (BOOL) string:(NSString*)string1 equals:(NSString*)string2;

// ==========================================================================
//
// findCRLFInResponseStartingAt:
//
//     Search self._response for a CR/LF combination starting at the given
//     index.
//
//     We return the index into self._response for the start of the CR/LF pair,
//     or the special value 'NSNotFound' if no CR/LF combination was found
//     starting at the given index.

- (NSUInteger) findCRLFInResponseStartingAt:(NSUInteger)index;

// ==========================================================================
//
// getStringFromResponseStartingAt:endingAt:encoding:
//
//     Extract a string from self.response, starting at the given start index
//     and ending at the given end index.  The data will be interpreted using
//     the given character encoding.

- (NSString*) getStringFromResponseStartingAt:(NSUInteger)start_index
                                     endingAt:(NSUInteger)end_index
                                     encoding:(NSStringEncoding)encoding;

// ==========================================================================
//
// dataToStringForDebugging:
//
//     Convert the given NSData object into a string for debugging.
//
//     Note that this is intended for debugging only.  We try various character
//     encodings until one works.  It's suitable for debugging, but isn't
//     entirely reliable.

- (NSString*) dataToStringForDebugging:(NSData*)data;

// ==========================================================================
//
// processResponse:
//
//     Process the response we have received from the remote server.
//
//     The response is in self._response.  Note that this may be a partial
//     response, in which case we simply wait until the entire response has
//     been received.
//
//     Once we have received the entire response, we pass the response on to
//     our "success" block, and change our state to "closed" or "ready" as
//     appropriate.

- (void) processResponse;

// ==========================================================================
//
// parseChunkedDataStartingAt:encoding:
//
//     Attempt to parse the contents of a response which has a
//     "Transfer-Encoding" header value of "chunked".  In this case, we have to
//     treat the body of the response as a series of chunks, and make sure all
//     the chunks are received before processing the response.
//
//     'offset' is the offset into self._response that marks the start of the
//     body of the response.
//
//     We identify the various chunks that make up the response body, and
//     combine them into a single NSData object which is then returned.  If the
//     response is incomplete, we return nil.

- (NSData*) parseChunkedDataStartingAt:(long)offset
                              encoding:(NSStringEncoding)encoding;

// ==========================================================================
//
// getEncodingFromHeaders:
//
//     Calculate the character encoding to use, based on the Content-Type
//     header, if any.
//
//     'headers' should be an NSArray of [header, value] arrays.
//
//     If we can't determine the character encoding, we return
//     NSASCIIStringEncoding.

- (NSStringEncoding) getEncodingFromHeaders:headers;

// ==========================================================================
//
// handleResponseWithStatus:headers:contents:encoding:
//
//     Handle a complete response being received from the server.  The response
//     will have the given status, headers, and contents, and the contents will
//     use the given character encoding.
//
//     We pass the response on to our current 'success' handler block.

- (void) handleResponseWithStatus:(int)status
                          headers:(NSArray*)headers
                         contents:(NSData*)contents
                         encoding:(NSStringEncoding)encoding;

// ==========================================================================
//
// finishedWithResponse
//
//     Update the connnection to reflect the fact that we've finished with the
//     current response.
//
//     We clear the contents of self._response so that we can start receiving a
//     new response when a new request is sent, and change our connection's
//     state to "ready".

- (void) finishedWithResponse;

// ==========================================================================

@end

// ##########################################################################

@implementation GIDHttpConnection

// ==========================================================================
// ==                                                                      ==
// ==                     P U B L I C   M E T H O D S                      ==
// ==                                                                      ==
// ==========================================================================

- (id) initWithURL:(NSURL*)url {

    if (self = [super init]) {

        NSString* scheme = [url scheme];
        BOOL useSSL = [self string:scheme equals:@"https"];

        int port;
        if (url.port != nil) {
            port = [url.port intValue];
        } else {
            if (useSSL) {
                port = 443;
            } else {
                port = 80;
            }
        }

#if DEBUG_MODE
        NSLog(@"Opening socket to %@, port %d, useSSL %d",
              [url host], port, useSSL);
#endif

        self._socket = [[GIDHttpSocket alloc] initWithServer:[url host]
                                                        port:port
                                                      useSSL:useSSL];
        self._url    = url;

        [self setState:kConnectionStateReady];
        [self._socket setDelegate:self];
    }

    return self;
}

// ==========================================================================

- (void) request:(NSString*)method
         headers:(NSArray*)headers
        contents:(NSString*)contents
  binary_request:(BOOL)binary_request
 binary_response:(BOOL)binary_response
      on_success:(void (^)(NSDictionary* http_response))success
        on_error:(void (^)(NSString* err_msg))error {

    // If we're not ready to send, return an error.

    if (self._state != kConnectionStateReady) {
        error(@"NOT READY");
        return;
    }

    // Build our HTTP request.

    NSString* path = [self._url path];
    if ([path length] == 0) {
        path = @"/";
    }

    NSMutableString* request = [[NSMutableString alloc] init];
    [request appendString:method];
    [request appendString:@" "];
    [request appendString:path];
    [request appendString:@" HTTP/1.1\r\n"];

    for (NSArray* row in headers) {
        NSString* key;
        NSString* value;

        if ([row[0] isKindOfClass:[NSString class]]) {
            key = row[0];
        } else {
            [NSException raise:@"Invalid header key"
                        format:@"Header %@ must be a string", row[0]];
        }

        if ([row[1] isKindOfClass:[NSString class]]) {
            value = row[1];
        } else if ([row[1] isKindOfClass:[NSNumber class]]) {
            value = [row[1] stringValue];
        } else {
            [NSException raise:@"Invalid header value"
                        format:@"Header %@ must be a number or string", row[1]];
        }

        [request appendString:key];
        [request appendString:@": "];
        [request appendString:value];
        [request appendString:@"\r\n"];
    }

    [request appendString:@"\r\n"];

    NSMutableData* request_data = [[NSMutableData alloc] init];
    [request_data appendData:[request dataUsingEncoding:NSASCIIStringEncoding]];

    if ([contents length] > 0) {
        if (binary_request) {
            NSData* binary_data = [[NSData alloc]
                                   initWithBase64EncodedString:contents
                                                       options:0];
            [request_data appendData:binary_data];
        } else {
            NSStringEncoding encoding = [self getEncodingFromHeaders:headers];
            [request_data appendData:[contents dataUsingEncoding:encoding]];
        }
    }

    // Remember the HTTP method we're using, so we can handle the response
    // appropriately based on the HTTP method.

    self._cur_method = method;

    // Remember if the caller requested a binary response.

    self._binary_response = binary_response;

    // Send the request to our TCP/IP socket.

    [self._socket send:request_data];

    // Remember our 'success' and 'error' blocks so we can call them once a
    // response has been received.

    self._success = success;
    self._error   = error;

    // Finally, update our state.

    [self setState:kConnectionStateSendingRequest];
}

// ==========================================================================

- (void) close {

    [self._socket close];
    self._socket = nil;
    self._state = kConnectionStateClosed;
}

// ==========================================================================
// ==                                                                      ==
// ==      G I D H T T P S O C K E T D E L E G A T E   M E T H O D S       ==
// ==                                                                      ==
// ==========================================================================

- (void) socket:(GIDHttpSocket*)socket sentData:(NSData*)data {

#if DEBUG_MODE
    NSString* s = [self dataToStringForDebugging:data];
    NSLog(@"SENT TO SOCKET: %@", s);
    NSLog(@"RAW DATA: %@", data);
#endif

    [self setState:kConnectionStateWaitingForResponse];
}

// ==========================================================================

- (void) socket:(GIDHttpSocket*)socket receivedData:(NSData*)data {

#if DEBUG_MODE
    NSString* s = [self dataToStringForDebugging:data];
    NSLog(@"RECEIVED FROM SOCKET: %@", s);
    NSLog(@"RAW DATA: %@", data);
#endif

    if (self._response == nil) {
        self._response = [[NSMutableData alloc] init];
    }

    [self._response appendData:data];
    [self processResponse];
}

// ==========================================================================

- (void) socket:(GIDHttpSocket*)socket hadError:(NSError*)error {

#if DEBUG_MODE
    NSLog(@"SOCKET ERROR: %ld - %@",
          (long)[error code], [error localizedDescription]);
#endif
}

// ==========================================================================

- (void) socketWasClosed:(GIDHttpSocket*)socket {

#if DEBUG_MODE
    NSLog(@"SOCKET WAS CLOSED");
#endif
}

// ==========================================================================
// ==                                                                      ==
// ==                   I N T E R N A L   M E T H O D S                    ==
// ==                                                                      ==
// ==========================================================================

- (void) setState:(GIDHttpConnectionState)state {

    self._state = state;
#if DEBUG_MODE
    NSString* s;
    if (state == kConnectionStateReady) {
        s = @"READY";
    } else if (state == kConnectionStateSendingRequest) {
        s = @"SENDING REQUEST";
    } else if (state == kConnectionStateWaitingForResponse) {
        s = @"WAITING FOR RESPONSE";
    } else if (state == kConnectionStateClosed) {
        s = @"CLOSED";
    } else {
        s = @"<<UNKNOWN>>";
    }

    NSLog(@"CHANGING CONNECTION STATE TO: %@", s);
#endif

}

// ==========================================================================

- (BOOL) string:(NSString*)string1 equals:(NSString*)string2 {

    if (string1 == nil) {
        return NO;
    } else if ([string1 compare:string2 options:NSCaseInsensitiveSearch] == NSOrderedSame) {
        return YES;
    } else {
        return NO;
    }
}

// ==========================================================================

- (NSUInteger) findCRLFInResponseStartingAt:(NSUInteger)index {

    NSData* crlf = [@"\r\n" dataUsingEncoding:NSASCIIStringEncoding];

    NSRange search_range = NSMakeRange(index,
                                       self._response.length - index);

    NSRange found = [self._response rangeOfData:crlf
                                        options:0
                                          range:search_range];

    return found.location;
}

// ==========================================================================

- (NSString*) getStringFromResponseStartingAt:(NSUInteger)start_index
                                     endingAt:(NSUInteger)end_index
                                     encoding:(NSStringEncoding)encoding {

    NSRange range = NSMakeRange(start_index, end_index-start_index+1);
    NSData* data  = [self._response subdataWithRange:range];
    NSString* s = [[NSString alloc] initWithData:data encoding:encoding];
    return s;
}

// ==========================================================================

- (NSString*) dataToStringForDebugging:(NSData*)data {

    NSString* s = [[NSString alloc] initWithData:data
                                        encoding:NSUTF8StringEncoding];
    if (s != nil) {
        return s;
    }

    s = [[NSString alloc] initWithData:data
                              encoding:NSISOLatin1StringEncoding];
    if (s != nil) {
        return s;
    }

    s = [[NSString alloc] initWithData:data
                              encoding:NSASCIIStringEncoding];
    if (s != nil) {
        return s;
    }

    return @"UNABLE TO ENCODE STRING!";
}

// ==========================================================================

- (void) processResponse {

    // Set the initial string encoding to use.  We assume the headers are in
    // plain ASCII.

    NSStringEncoding encoding = NSASCIIStringEncoding; // initially.

    // Parse the HTTP response status line.

    NSUInteger eol = [self findCRLFInResponseStartingAt:0];
    if (eol == NSNotFound) {
        return;
    }

    NSString* status_line = [self getStringFromResponseStartingAt:0
                                                         endingAt:eol-1
                                                         encoding:encoding];

    if (![status_line hasPrefix:@"HTTP/"]) {
        NSString* error = [NSString stringWithFormat:@"Invalid status line: %@",
                           status_line];
        self._error(error);
        [self finishedWithResponse];
        return;
    }

    NSArray* parts = [status_line componentsSeparatedByString:@" "];
    if ([parts count] < 3) {
        NSString* error = [NSString stringWithFormat:@"Invalid status line: %@",
                           status_line];
        self._error(error);
        [self finishedWithResponse];
        return;
    }

    int status = [parts[1] intValue];
    //NSLog(@"Status = %d", status);

    // Extract the response headers.

    NSMutableArray* headers = [[NSMutableArray alloc] init];

    NSUInteger start_of_line = eol + 2;

    while (start_of_line < [self._response length] - 2) {
        eol = [self findCRLFInResponseStartingAt:start_of_line];
        if (eol == NSNotFound) {
            break;
        }

        //NSLog(@"Found line from %ld to %ld", (long)start_of_line,
        //                                     (long)eol);

        NSString* line = [self getStringFromResponseStartingAt:start_of_line
                                                      endingAt:eol-1
                                                      encoding:encoding];

        if ([line length] == 0) {
            break;
        }

        NSRange range = [line rangeOfString:@":"];
        if (range.location == NSNotFound) {
            NSString* error =
                [NSString stringWithFormat:@"Malformed header line: %@",
                                           status_line];
            self._error(error);
            [self finishedWithResponse];
            return;
        }

        NSString* header = [line substringToIndex:range.location];
        NSString* value  = [line substringFromIndex:range.location+1];

        NSCharacterSet* whitespace = [NSCharacterSet whitespaceCharacterSet];
        header = [header stringByTrimmingCharactersInSet:whitespace];
        value  = [value  stringByTrimmingCharactersInSet:whitespace];

        [headers addObject:@[header, value]];

        start_of_line = eol + 2;
    }

    // See if this request can have a message body (for details, see
    // http://www.w3.org/Protocols/rfc2616/rfc2616-sec4.html#sec4.4).

    if (((status >= 100) && (status <= 199))
          || (status == 204) || (status == 304)
                             || [self._cur_method isEqualToString:@"HEAD"]) {
        // This response can't have a body -> return just the status and
        // headers, with an empty contents.
        [self handleResponseWithStatus:status
                               headers:headers
                              contents:[NSData data]
                              encoding:encoding];
        [self finishedWithResponse];
        return;
    }

    // Calculate the encoding to use for the rest of the response, based on the
    // supplied Content-Type header.

    encoding = [self getEncodingFromHeaders:headers];

    // We now have to process the response contents, if any.

    long start_of_contents = start_of_line + 2; // Skip CR/LF.

    // If we have a "Transfer-Encoding" header with a value of "chunked", then
    // the contents will be sent through in chunks.  We process this specially.

    BOOL chunked = NO;
    for (NSArray* row in headers) {
        NSString* header = row[0];
        NSString* value  = row[1];

        if ([self string:header equals:@"TRANSFER-ENCODING"]) {
            if ([self string:value equals:@"CHUNKED"]) {
                chunked = YES;
            }
        }
    }

    if (chunked) {
        NSData* chunked_contents =
            [self parseChunkedDataStartingAt:start_of_contents
                                    encoding:encoding];

        if (chunked_contents != nil) {
            [self handleResponseWithStatus:status
                                   headers:headers
                                  contents:chunked_contents
                                  encoding:encoding];
            [self finishedWithResponse];
            return;
        } else {
            // We haven't received all the chunks -> wait until we have.
            return;
        }
    }

    // If we have a Content-Length header, use that to determine the length of
    // the message body.

    long content_length = -1;
    for (NSArray* row in headers) {
        NSString* header = row[0];
        NSString* value  = row[1];

        if ([self string:header equals:@"CONTENT-LENGTH"]) {
            content_length = [value intValue];
        }
    }

    if (content_length != -1) {
        if (start_of_contents + content_length > [self._response length]) {
            // We haven't received all our contents yet -> wait for the rest of
            // the contents to come in.
            return;
        }

        // If we get here, we have the content-length and all the contents we
        // need -> return them to our success handler.

        NSRange range = NSMakeRange(start_of_contents, content_length);
        NSData* contents = [self._response subdataWithRange:range];

        [self handleResponseWithStatus:status
                               headers:headers
                              contents:contents
                              encoding:encoding];
        [self finishedWithResponse];
        return;
    }

    // If we get here, we have a response with no Content-Length header.  In
    // this case, we assume the response has no body, but raise an error if we
    // have received some contents.
    //
    // NOTE: Apparently it's possible for a response to have contents but no
    // Content-Length header.  In this case, we are supposed to keep the
    // connection open until the server closes it, at which time we assume all
    // accumulated data is the contents we were supposed to receive.  We're not
    // doing that at the moment.

    if (start_of_contents == [self._response length]) {
        // No contents -> process the response with no body.
        [self handleResponseWithStatus:status
                               headers:headers
                              contents:[NSData data]
                              encoding:encoding];
        [self finishedWithResponse];
    } else {
        self._error(@"Unable to calculate response body length.");
        [self finishedWithResponse];
    }
}

// ==========================================================================

- (NSData*) parseChunkedDataStartingAt:(long)offset
                              encoding:(NSStringEncoding)encoding {

    NSMutableData* chunked_data = [[NSMutableData alloc] init];

    while (offset < [self._response length]) {
        NSUInteger eol = [self findCRLFInResponseStartingAt:offset];
        if (eol == NSNotFound) {
            return nil; // Incomplete response.
        }

        NSString* line = [self getStringFromResponseStartingAt:offset
                                                      endingAt:eol-1
                                                      encoding:encoding];
        unsigned int chunk_length;
        NSScanner* scanner = [NSScanner scannerWithString:line];
        [scanner scanHexInt:&chunk_length];

        if (chunk_length == 0) {
            // We've reached the end of the chunked data.  Success!
            return chunked_data;
        }

        offset = eol + 2; // Skip to start of next line.

        if (offset + chunk_length > [self._response length]) {
            return nil; // Incomplete response.
        }

        NSRange range = NSMakeRange(offset, chunk_length);
        [chunked_data appendData:[self._response subdataWithRange:range]];

        offset = offset + chunk_length + 2; // Skip CR/LF at end of chunk.
    }
    return nil; // Incomplete response.
}

// ==========================================================================

- (NSStringEncoding) getEncodingFromHeaders:headers {

    for (NSArray* row in headers) {
        NSString* header = row[0];
        NSString* value  = row[1];

        if ([self string:header equals:@"CONTENT-TYPE"]) {
            if ([self string:value equals:@"APPLICATION/JSON"]) {
                // JSON data always uses UTF-8 character encoding.
                return NSUTF8StringEncoding;
            } else {
                // See if the content type includes a "charset" specifier.
                NSRange range = [value rangeOfString:@"charset="
                                             options:NSCaseInsensitiveSearch];
                if (range.location != NSNotFound) {
                    NSString* charset = [value substringFromIndex:range.location+8];
                    if ([self string:charset equals:@"UTF-8"]) {
                        return NSUTF8StringEncoding;
                    } else if ([self string:charset equals:@"ISO-8859-1"]) {
                        return NSISOLatin1StringEncoding;
                    }
                }
            }
        }
    }

    return NSASCIIStringEncoding; // Best fallback?
}

// ==========================================================================

- (void) handleResponseWithStatus:(int)status
                          headers:(NSArray*)headers
                         contents:(NSData*)contents
                         encoding:(NSStringEncoding)encoding {

    NSString* contents_string;

    if (self._binary_response) {
        // Encode the binary response using base-64 encoding.
        contents_string = [contents base64EncodedStringWithOptions:0];
    } else {
        // Use the supplied character encoding to return the string directly.
        contents_string = [[NSString alloc] initWithData:contents
                                                encoding:encoding];
    }

    NSDictionary* response = @{@"status" : [NSNumber numberWithInt:status],
                              @"headers" : headers,
                             @"contents" : contents_string};

    self._success(response);
}

// ==========================================================================

- (void) finishedWithResponse {

    [self._response setLength:0];
    self._cur_method = nil;
    self.state       = kConnectionStateReady; // Always?
}

// ==========================================================================

@end
