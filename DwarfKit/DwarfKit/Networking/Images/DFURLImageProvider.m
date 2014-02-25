/*
 The MIT License (MIT)
 
 Copyright (c) 2013 Alexander Grebenyuk (github.com/kean).
 
 Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:
 
 The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.
 
 THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
 */

#import "DFCache+UIImage.h"
#import "DFImageProcessing.h"
#import "DFURLImageProvider.h"
#import "DFURLSessionHTTPRequest.h"

@implementation DFURLImageProvider

+ (instancetype)shared {
    static DFURLImageProvider *_shared = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        _shared = [[self class] new];
    });
    return _shared;
}

- (id)init {
    if (self = [super init]) {
        DFURLSessionTaskConfiguration *conf = [DFURLSessionTaskConfiguration new];
        conf.deserializer = [[DFURLResponseDeserializer alloc] initWithValidation:nil deserialization:^id(NSURLResponse *response, NSData *data, NSError *__autoreleasing *error) {
            return [DFImageProcessing decompressedImageWithData:data];
        }];
        conf.cancelsWhenZeroHandlers = YES;
        conf.cachingEnabled = NO;
        conf.retryConfiguration = [DFURLRetryConfiguration defaultConfiguration];
        
        NSOperationQueue *queue = [NSOperationQueue new];
        queue.maxConcurrentOperationCount = 3;
        
        _session = [[DFURLSession alloc] initWithQueue:queue taskConfiguration:conf requestConstructor:nil];
        
        _cache = [DFCache imageCache];
    }
    return self;
}

- (UIImage *)memoryCachedImageWithURL:(NSString *)URL {
    return [_cache.memoryCache objectForKey:URL];
}

- (void)cachedImageWithURL:(NSString *)URL completion:(void (^)(UIImage *))completion {
    [_cache cachedImageForKey:URL completion:completion];
}

- (void)imageWithURL:(NSString *)URL handler:(id)handler completion:(void (^)(UIImage *, NSError *, DFURLSessionTask *))completion {
    DFURLSessionTask *task = [_session taskPassingTest:^BOOL(DFURLSessionTask *task) {
        return [task.userInfo isEqualToString:URL];
    }];
    if (!task || task.state == DFURLSessionTaskStateCancelled) {
        NSURLRequest *request = [[NSURLRequest alloc] initWithURL:[NSURL URLWithString:URL] cachePolicy:NSURLRequestReloadIgnoringCacheData timeoutInterval:60.f];
        task = [_session taskWithRequest:[[DFURLSessionHTTPRequest alloc] initWithRequest:request]];
        task.userInfo = URL;
        [task addObserver:self forKeyPath:@"state" options:NSKeyValueObservingOptionNew context:nil];
    }
    [task addHandler:handler success:^(DFURLSessionResponse *response, DFURLSessionTask *task) {
        if (completion) {
            completion(response.object, nil, task);
        }
    } failure:^(NSError *error, DFURLSessionTask *task) {
        if (completion) {
            completion(nil, error, task);
        }
    }];
}

- (void)cancelImageRequestWithURL:(NSString *)URL handler:(id)handler {
    [[_session taskPassingTest:^BOOL(DFURLSessionTask *task) {
        return [task.userInfo isEqualToString:URL];
    }] removeHandler:handler];
}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context {
    if ([object isKindOfClass:[DFURLSessionTask class]]) {
        DFURLSessionTask *task = object;
        if (task.state == DFURLSessionTaskStateSucceed) {
            [_cache storeImage:task.response.object imageData:task.response.data forKey:task.userInfo];
        }
        if ([DFURLSessionTask isStateFinal:task.state]) {
            [task removeObserver:self forKeyPath:@"state"];
        }
    }
}

@end
