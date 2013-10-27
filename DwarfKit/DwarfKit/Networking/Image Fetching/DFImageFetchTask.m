/*
 The MIT License (MIT)
 
 Copyright (c) 2013 Alexander Grebenyuk (github.com/kean).
 
 Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:
 
 The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.
 
 THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
 */

#import "DFImageFetchTask.h"
#import "DFImageProcessing.h"
#import "DFCache.h"


static NSString * const _kLastModifiedKey = @"Last-Modified";
static NSString * const _kIfModifiedSinceKey = @"If-Modified-Since";


@interface DFImageFetchTask() <NSURLConnectionDataDelegate>

@end


@implementation DFImageFetchTask {
    NSHTTPURLResponse *_response;
    NSMutableData *_data;
    NSString *_ifModifiedSince;
    BOOL _revalidate;
}

- (id)initWithURL:(NSString *)imageURL revalidate:(BOOL)revalidate ifModifiedSince:(NSString *)ifModifiedSince {
    if (self = [super init]) {
        _imageURL = imageURL;
        _ifModifiedSince = ifModifiedSince;
        _revalidate = revalidate;
    }
    return self;
}

- (id)initWithURL:(NSString *)imageURL {
    return [self initWithURL:imageURL revalidate:NO ifModifiedSince:nil];
}

- (NSUInteger)hash {
    return [_imageURL hash];
}

#pragma mark - Task Implementation

- (void)execute {
    if ([self isCancelled]) {
        [self finish];
        return;
    }
    
    NSURLRequest *request = [self _requestWithURL:_imageURL];
    
    NSURLConnection *connection =
    [[NSURLConnection alloc] initWithRequest:request
                                    delegate:self
                            startImmediately:NO];
    if (connection == nil) {
        [self finish];
        return;
    }
    
    if ([self isCancelled]) {
        [self finish];
        return;
    }
    
    [connection scheduleInRunLoop:[NSRunLoop mainRunLoop] forMode:NSRunLoopCommonModes];
    [connection start];
}

- (NSURLRequest *)_requestWithURL:(NSString *)imageURL {
    NSURL *URL = [NSURL URLWithString:imageURL];
    NSMutableURLRequest *request = [[NSMutableURLRequest alloc] initWithURL:URL cachePolicy:NSURLRequestUseProtocolCachePolicy timeoutInterval:30.f];
    [request setHTTPShouldHandleCookies:NO];
    [request setHTTPShouldUsePipelining:YES];
    if (_revalidate && _ifModifiedSince) {
        [request setValue:_ifModifiedSince forHTTPHeaderField:_kIfModifiedSinceKey];
    }
    return request;
}

#pragma mark - NSURLConnectionDelegate

- (void)connection:(NSURLConnection *)connection didReceiveResponse:(NSURLResponse *)response {
    _data = [NSMutableData data];
}

- (void)connection:(NSURLConnection *)connection didReceiveData:(NSData *)data {
    [_data appendData:data];
}

- (NSCachedURLResponse *)connection:(NSURLConnection *)connection willCacheResponse:(NSCachedURLResponse *)cachedResponse {
    return nil;
}

- (void)connectionDidFinishLoading:(NSURLConnection *)connection {
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        @autoreleasepool {
            _image = [DFImageProcessing decompressedImageWithData:_data];
            if (_image) {
                [_delegate imageFetchTaskDidFinishProcessingImage:self];
            }
            [self finish];
        }
    });
}

- (void)connection:(NSURLConnection *)connection didFailWithError:(NSError *)error {
    _error = error;
    [self finish];
}

@end
