/*
 The MIT License (MIT)
 
 Copyright (c) 2013 Alexander Grebenyuk (github.com/kean).
 
 Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:
 
 The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.
 
 THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
 */

#import "DFImageFetchTask.h"
#import "DFImageProcessing.h"


@interface DFImageFetchTask() <NSURLConnectionDataDelegate>

@end


@implementation DFImageFetchTask {
   NSMutableData *_imageData;
}


- (id)initWithURL:(NSString *)imageURL {
   if (self = [super init]) {
      _imageURL = imageURL;
   }
   return self;
}


- (NSUInteger)hash {
   return [_imageURL hash];
}

#pragma mark - Task Implementation

- (void)execute {
   if (_cache) {
      [self _checkCaches];
   } else {
      [self _fetchImage];
   }
}


- (void)_checkCaches {
   _image = [_cache imageForKey:_imageURL];
   if (_image) {
      _source = DFResponseSourceMemory;
      [self finish];
      return;
   }
   
   dispatch_queue_t queue = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0);
   [_cache imageForKey:_imageURL
                 queue:queue
            completion:^(UIImage *image) {
      if (image) {
         _image = image;
         _source = DFResponseSourceDisk;
         [self finish];
      } else {
         [self _fetchImage];
      }
   }];
}


- (void)_fetchImage {
   if ([self isCancelled]) {
      [self finish];
      return;
   }
   
   NSURLRequest *request;
   if (_requestBlock) {
      request = _requestBlock(_imageURL, self);
   } else {
      request = [self _requestWithURL:_imageURL];
   }
   
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
   return request;
}

#pragma mark - NSURLConnectionDelegate

- (void)connection:(NSURLConnection *)connection didReceiveResponse:(NSURLResponse *)response {
   _imageData = [NSMutableData data];
}


- (void)connection:(NSURLConnection *)connection didReceiveData:(NSData *)data {
   [_imageData appendData:data];
}


- (NSCachedURLResponse *)connection:(NSURLConnection *)connection willCacheResponse:(NSCachedURLResponse *)cachedResponse {
   if (_cache) {
      return nil;
   }
   return cachedResponse;
}


- (void)connectionDidFinishLoading:(NSURLConnection *)connection {
   dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
      @autoreleasepool {
         _image = [DFImageProcessing decompressedImageWithData:_imageData];
         if (_image == nil) {
            [self finish];
            return;
         }
         
         [_cache storeImage:_image
                  imageData:_imageData
                     forKey:_imageURL];
         _source = DFResponseSourceMemory;
         [self finish];
      }
   });
}


- (void)connection:(NSURLConnection *)connection didFailWithError:(NSError *)error {
   _error = error;
   [self finish];
}

@end
