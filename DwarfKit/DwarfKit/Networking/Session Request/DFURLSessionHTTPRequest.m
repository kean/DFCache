/*
 The MIT License (MIT)
 
 Copyright (c) 2013 Alexander Grebenyuk (github.com/kean).
 
 Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:
 
 The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.
 
 THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
 */

#import "DFURLSessionHTTPRequest.h"

@implementation DFURLSessionHTTPRequest {
    NSURLRequest *_request;
    NSString *_HTTPMethod;
    NSString *_baseURL;
    NSString *_path;
    id _parameters;
}

- (id)initWithHTTPMethod:(NSString *)method baseURL:(NSString *)baseURL path:(NSString *)path parameters:(id)parameters {
    if (self = [super init]) {
        _HTTPMethod = method;
        _baseURL = baseURL;
        _path = path;
        _parameters = parameters;
    }
    return self;
}

- (id)initWithHTTPMethod:(NSString *)method path:(NSString *)path parameters:(id)parameters {
    return [self initWithHTTPMethod:method baseURL:nil path:path parameters:parameters];
}

- (id)initWithRequest:(NSURLRequest *)request parameters:(id)parameters {
    if (self = [super init]) {
        _request = request;
        _parameters = parameters;
    }
    return self;
}

- (id)initWithRequest:(NSURLRequest *)request {
    return [self initWithRequest:request parameters:nil];
}

#pragma mark - <DFURLSessionRequest>

- (NSURLRequest *)currentRequest {
    @synchronized(self) {
        if (!_request) {
            NSURL *URL = _baseURL.length ? [NSURL URLWithString:_path relativeToURL:[NSURL URLWithString:_baseURL]] : [NSURL URLWithString:_path];
            _request = [[NSURLRequest alloc] initWithURL:URL];
        }
    }
    return _constructor ? [_constructor requestWithRequest:_request parameters:_parameters error:nil] : _request;
}

@end
