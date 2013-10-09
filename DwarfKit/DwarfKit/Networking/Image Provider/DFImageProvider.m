/*
 The MIT License (MIT)
 
 Copyright (c) 2013 Alexander Grebenyuk (github.com/kean).
 
 Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:
 
 The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.
 
 THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
 */

#import "DFImageProvider.h"
#import "DFReusablePool.h"


#pragma mark - _DFFetchWrapper -

@interface _DFProviderWrapper : NSObject <DFReusable>

@property (nonatomic) NSString *imageURL;
@property (nonatomic) DFImageProviderTask *task;
@property (nonatomic) NSMutableArray *handlers;

- (id)initWithTask:(DFImageProviderTask *)task
          imageURL:(NSString *)imageURL
           handler:(DFImageProviderHandler *)handler;

- (void)prepareForReuse;

@end

@implementation _DFProviderWrapper

- (id)initWithTask:(DFImageProviderTask *)task
          imageURL:(NSString *)imageURL
           handler:(DFImageProviderHandler *)handler {
    if (self = [super init]) {
        _imageURL = imageURL;
        _task = task;
        _handlers = [NSMutableArray arrayWithObject:handler];
    }
    return self;
}

- (void)prepareForReuse {
    _imageURL = nil;
    _task = nil;
    [_handlers removeAllObjects];
}

@end


#pragma mark - DFImageProvider -

@implementation DFImageProvider {
    NSMutableDictionary *_wrappers;
    DFReusablePool *_reusableWrappers;
}

- (id)init {
    if (self = [super init]) {
        _queue = [DFTaskQueue new];
        _wrappers = [NSMutableDictionary new];
        _reusableWrappers = [DFReusablePool new];
        [self _setDefaults];
    }
    return self;
}

- (void)_setDefaults {
    _queue.maxConcurrentTaskCount = 20;
}

#pragma mark - Requests

- (DFImageProviderTask *)requestImageWithURL:(NSString *)imageURL handler:(DFImageProviderHandler *)handler {
    if (!imageURL || !handler) {
        return nil;
    }
    _DFProviderWrapper *wrapper = [_wrappers objectForKey:imageURL];
    if (wrapper) {
        [wrapper.handlers addObject:handler];
        return wrapper.task;
    } else {
        DFImageProviderTask *task = [[DFImageProviderTask alloc] initWithURL:imageURL];
        [task setCompletion:^(DFTask *completedTask) {
            [self _handleTaskCompletion:(id)completedTask];
        }];
        
        _DFProviderWrapper *wrapper = [_reusableWrappers dequeueObject];
        if (wrapper) {
            wrapper.task = task;
            wrapper.imageURL = imageURL;
            [wrapper.handlers addObject:handler];
        } else {
            wrapper = [[_DFProviderWrapper alloc] initWithTask:task imageURL:imageURL handler:handler];
        }
        [_wrappers setObject:wrapper forKey:imageURL];
        
        [_queue addTask:task];
        return task;
    }
}

- (void)cancelRequestWithURL:(NSString *)imageURL handler:(DFImageProviderHandler *)handler {
    if (!handler || !imageURL) {
        return;
    }
    _DFProviderWrapper *wrapper = [_wrappers objectForKey:imageURL];
    if (!wrapper) {
        return;
    }
    [wrapper.handlers removeObject:handler];
    if (wrapper.handlers.count == 0 && !wrapper.task.isFetching) {
        [wrapper.task cancel];
        [wrapper.task setCompletion:nil];
        [_wrappers removeObjectForKey:imageURL];
        [_reusableWrappers enqueueObject:wrapper];
    }
}

#pragma mark - DFImageProviderTask Completion

- (void)_handleTaskCompletion:(DFImageProviderTask *)task {
    if (task.isCancelled) {
        return;
    }
    _DFProviderWrapper *wrapper = [_wrappers objectForKey:task.imageURL];
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
    [_wrappers removeObjectForKey:task.imageURL];
    [_reusableWrappers enqueueObject:wrapper];
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
