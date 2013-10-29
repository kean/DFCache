/*
 The MIT License (MIT)
 
 Copyright (c) 2013 Alexander Grebenyuk (github.com/kean).
 
 Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:
 
 The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.
 
 THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
 */

#import "DFImageFetchManager.h"
#import "DFTaskMultiplexer.h"
#import "DFCache.h"


@implementation DFImageFetchManager {
    DFTaskMultiplexer *_multiplexer;
}

- (id)init {
    if (self = [super init]) {
        _multiplexer = [DFTaskMultiplexer new];
        _queue = [DFTaskQueue new];
        _queue.maxConcurrentTaskCount = 3;
    }
    return self;
}
#pragma mark - Fetching

- (DFImageFetchTask *)fetchImageWithURL:(NSString *)imageURL handler:(DFImageFetchHandler *)handler revalidate:(BOOL)revalidate ifModifiedSince:(NSString *)ifModifiedSince {
    if (!imageURL || !handler) {
        return nil;
    }
    DFTaskWrapper *wrapper = [_multiplexer addHandler:handler withKey:imageURL];
    if (wrapper) {
        return (id)wrapper.task;
    }
    DFImageFetchTask *task = [[DFImageFetchTask alloc] initWithURL:imageURL revalidate:revalidate ifModifiedSince:ifModifiedSince];
    task.delegate = self;
    [_multiplexer addTask:task withKey:imageURL handler:handler];
    [_queue addTask:task];
    return task;
}

- (DFImageFetchTask *)fetchImageWithURL:(NSString *)imageURL handler:(DFImageFetchHandler *)handler {
    return [self fetchImageWithURL:imageURL handler:handler revalidate:NO ifModifiedSince:nil];
}

- (void)cancelFetchingWithURL:(NSString *)imageURL handler:(DFImageFetchHandler *)handler {
    if (!handler || !imageURL) {
        return;
    }
    DFTaskWrapper *wrapper = [_multiplexer removeHandler:handler withKey:imageURL];
    if (wrapper.handlers.count == 0 && !wrapper.task.isExecuting) {
        [wrapper.task cancel];
        [_multiplexer removeTaskWithKey:imageURL];
    }
}

#pragma mark - DFImageFetchTaskDelegate

- (void)imageFetchTaskDidFinishProcessingImage:(DFImageFetchTask *)task {
    [[DFCache imageCache] storeImage:task.image imageData:task.data forKey:task.imageURL];
}

@end


@implementation DFImageFetchManager (Shared)

+ (instancetype)shared {
    static DFImageFetchManager *shared = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        shared = [[self class] new];
    });
    return shared;
}

@end

