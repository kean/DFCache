/*
 The MIT License (MIT)
 
 Copyright (c) 2013 Alexander Grebenyuk (github.com/kean).
 
 Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:
 
 The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.
 
 THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
 */

#import "DFURLConnectionOperationDelegate.h"
#import "DFURLResponseDeserializing.h"
#import "DFURLSessionRequest.h"
#import "DFURLSessionResponse.h"


extern NSString *const DFURLConnectionDidStartNotification;
extern NSString *const DFURLConnectionDidStopNotification;


@interface DFURLConnectionOperation : NSOperation <NSURLConnectionDataDelegate, NSLocking>

@property (nonatomic, weak) id<DFURLConnectionOperationDelegate> delegate;
@property (nonatomic) id<DFURLResponseDeserializing> deserializer;
@property (nonatomic) BOOL cachingEnabled;
@property (nonatomic) NSSet *runLoopModes;

@property (nonatomic, readonly) id<DFURLSessionRequest> request;
@property (nonatomic, readonly) DFURLSessionResponse *response;
@property (nonatomic, readonly) NSError *error;

- (id)initWithSessionRequest:(id<DFURLSessionRequest>)request;
- (id)initWithRequest:(NSURLRequest *)request;

@end


@interface DFURLConnectionOperation (HTTP)

@property (nonatomic, readonly) NSHTTPURLResponse *HTTPResponse;

@end
