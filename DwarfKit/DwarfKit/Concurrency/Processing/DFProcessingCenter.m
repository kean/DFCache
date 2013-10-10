/*
 The MIT License (MIT)
 
 Copyright (c) 2013 Alexander Grebenyuk (github.com/kean).
 
 Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:
 
 The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.
 
 THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
 */

#import "DFProcessingCenter.h"
#import "DFReusablePool.h"


#pragma mark - _DFProcessingWrapper -

@interface _DFProcessingWrapper : NSObject <DFReusable>

@property (nonatomic, strong) NSString *key;
@property (nonatomic, strong) DFProcessingTask *task;
@property (nonatomic, strong) NSMutableArray *handlers;

- (id)initWithTask:(DFProcessingTask *)task key:(NSString *)key handler:(DFProcessingHandler *)handler;

@end

@implementation _DFProcessingWrapper

- (id)initWithTask:(DFProcessingTask *)task key:(NSString *)key handler:(DFProcessingHandler *)handler {
    if (self = [super init]) {
        _key = key;
        _task = task;
        _handlers = [NSMutableArray arrayWithObject:handler];
    }
    return self;
}

- (void)prepareForReuse {
    _key = nil;
    _task = nil;
    [_handlers removeAllObjects];
}

@end


#pragma mark - DFProcessingCenter

@implementation DFProcessingCenter {
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
    _queue.maxConcurrentTaskCount = 2;
}

#pragma mark - Requests

- (DFProcessingTask *)processInput:(id)input key:(NSString *)key handler:(DFProcessingHandler *)handler usingBlock:(id (^)(id))processingBlock {
    if (!key || !input || !processingBlock) {
        return nil;
    }
    _DFProcessingWrapper *wrapper = [_wrappers objectForKey:key];
    if (wrapper) {
        [wrapper.handlers addObject:handler];
        return wrapper.task;
    } else {
        DFProcessingTask *task = [[DFProcessingTask alloc] initWithInput:input key:key processingBlock:processingBlock];
        [task setCompletion:^(DFTask *completedTask) {
            [self _handleTaskCompletion:(id)completedTask];
        }];
        
        _DFProcessingWrapper *wrapper = [_reusableWrappers dequeueObject];
        if (wrapper) {
            wrapper.task = task;
            wrapper.key = key;
            [wrapper.handlers addObject:handler];
        } else {
            wrapper = [[_DFProcessingWrapper alloc] initWithTask:task key:key handler:handler];
        }
        [_wrappers setObject:wrapper forKey:key];
        
        [_queue addTask:task];
        return task;
    }
}

- (void)cancelProcessingWithKey:(NSString *)key handler:(DFProcessingHandler *)handler {
    if (!handler || !key) {
        return;
    }
    _DFProcessingWrapper *wrapper = [_wrappers objectForKey:key];
    if (!wrapper) {
        return;
    }
    [wrapper.handlers removeObject:handler];
    if (wrapper.handlers.count == 0) {
        [wrapper.task cancel];
        [wrapper.task setCompletion:nil];
        [_wrappers removeObjectForKey:key];
        [_reusableWrappers enqueueObject:wrapper];
    }
}

#pragma mark - DFProcessingTask Completion

- (void)_handleTaskCompletion:(DFProcessingTask *)task {
    if (task.isCancelled) {
        return;
    }
    _DFProcessingWrapper *wrapper = [_wrappers objectForKey:task.key];
    for (DFProcessingHandler *handler in wrapper.handlers) {
        handler.completion(task.output, task.fromCache);
    }
    [_wrappers removeObjectForKey:task.key];
    [_reusableWrappers enqueueObject:wrapper];
}

@end
