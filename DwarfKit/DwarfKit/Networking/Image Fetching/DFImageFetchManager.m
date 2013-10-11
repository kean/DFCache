/*
 The MIT License (MIT)
 
 Copyright (c) 2013 Alexander Grebenyuk (github.com/kean).
 
 Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:
 
 The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.
 
 THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
 */

#import "DFImageFetchManager.h"
#import "DFTaskMultiplexer.h"


@interface DFImageFetchManager() <DFTaskMultiplexerDelegate>

@end


@implementation DFImageFetchManager {
    DFTaskMultiplexer *_multiplexer;
}

- (id)init {
    if (self = [super init]) {
        _multiplexer = [DFTaskMultiplexer new];
        _multiplexer.queue.maxConcurrentTaskCount = 3;
        _multiplexer.delegate = self;
    }
    return self;
}

#pragma mark - Fetching

- (DFImageFetchTask *)fetchImageWithURL:(NSString *)imageURL handler:(DFImageFetchHandler *)handler {
    if (!imageURL || !handler) {
        return nil;
    }
    DFTaskWrapper *wrapper = [_multiplexer addHandler:handler withToken:imageURL];
    if (wrapper) {
        return (id)wrapper.task;
    }
    DFImageFetchTask *task = [[DFImageFetchTask alloc] initWithURL:imageURL];
    [_multiplexer addTask:task withToken:imageURL handler:handler];
    return task;
}

- (void)cancelFetchingWithURL:(NSString *)imageURL handler:(DFImageFetchHandler *)handler {
    if (!handler || !imageURL) {
        return;
    }
    DFTaskWrapper *wrapper = [_multiplexer removeHandler:handler withToken:imageURL];
    if (wrapper.handlers.count == 0 && !wrapper.task.isExecuting) {
        [_multiplexer cancelTaskWithToken:imageURL];
    }
}

- (void)prefetchImageWithURL:(NSString *)imageURL {
    [self fetchImageWithURL:imageURL handler:[DFImageFetchHandler new]];
}

#pragma mark - DFTaskMultiplexer Delegate

- (void)handleTaskCompletion:(DFTaskWrapper *)wrapper {
    DFImageFetchTask *imageTask = (id)wrapper.task;
    if (imageTask.image) {
        for (DFImageFetchHandler *handler in wrapper.handlers) {
            if (handler.success) {
                handler.success(imageTask.image);
            }
        }
    } else {
        for (DFImageFetchHandler *handler in wrapper.handlers) {
            if (handler.failure) {
                handler.failure(imageTask.error);
            }
        }
    }
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
