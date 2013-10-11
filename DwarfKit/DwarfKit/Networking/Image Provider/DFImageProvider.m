/*
 The MIT License (MIT)
 
 Copyright (c) 2013 Alexander Grebenyuk (github.com/kean).
 
 Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:
 
 The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.
 
 THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
 */

#import "DFImageProvider.h"
#import "DFTaskMultiplexer.h"


@interface DFImageProvider() <DFTaskMultiplexerDelegate>

@end


@implementation DFImageProvider {
    DFTaskMultiplexer *_multiplexer;
}

- (id)init {
    if (self = [super init]) {
        _multiplexer = [DFTaskMultiplexer new];
        _multiplexer.queue.maxConcurrentTaskCount = 20;
        _multiplexer.delegate = self;
    }
    return self;
}

#pragma mark - Requests

- (DFImageProviderTask *)requestImageWithURL:(NSString *)imageURL handler:(DFImageProviderHandler *)handler {
    if (!imageURL || !handler) {
        return nil;
    }
    DFTaskWrapper *wrapper = [_multiplexer addHandler:handler withToken:imageURL];
    if (wrapper) {
        return (id)wrapper.task;
    }
    DFImageProviderTask *task = [[DFImageProviderTask alloc] initWithURL:imageURL];
    [_multiplexer addTask:task withToken:imageURL handler:handler];
    return task;
}

- (void)cancelRequestWithURL:(NSString *)imageURL handler:(DFImageProviderHandler *)handler {
    if (!imageURL || !handler) {
        return;
    }
    DFTaskWrapper *wrapper = [_multiplexer removeHandler:handler withToken:imageURL];
    DFImageProviderTask *task = (id)wrapper.task;
    if (wrapper.handlers.count == 0 && !task.isFetching) {
        [_multiplexer cancelTaskWithToken:imageURL];
    }
}

#pragma mark - DFTaskMultiplexer Delegate

- (void)multiplexer:(DFTaskMultiplexer *)multiplexer didCompleteTask:(DFTaskWrapper *)wrapper {
    DFImageProviderTask *task = (id)wrapper.task;
    if (task.image) {
        for (DFImageProviderHandler *handler in wrapper.handlers) {
            if (handler.success) {
                handler.success(task.image, task.source);
            }
        }
    } else {
        for (DFImageProviderHandler *handler in wrapper.handlers) {
            if (handler.failure) {
                handler.failure(task.error);
            }
        }
    }
}

@end


@implementation DFImageProvider (Shared)

+ (instancetype)shared {
    static DFImageProvider *shared = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        shared = [[self class] new];
    });
    return shared;
}

@end
