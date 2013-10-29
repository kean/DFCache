/*
 The MIT License (MIT)
 
 Copyright (c) 2013 Alexander Grebenyuk (github.com/kean).
 
 Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:
 
 The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.
 
 THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
 */

#import "DFReusablePool.h"
#import "DFTask.h"
#import "DFTaskMultiplexer.h"


@implementation DFTaskWrapper

- (id)initWithTask:(DFTask *)task handler:(id)handler {
    if (self = [super init]) {
        _task = task;
        _handlers = [NSMutableArray arrayWithObject:handler];
    }
    return self;
}

- (void)prepareForReuse {
    _task = nil;
    [_handlers removeAllObjects];
}

@end


@implementation DFTaskMultiplexer {
    NSMutableDictionary *_wrappers;
    DFReusablePool *_reusableWrappers;
}

- (id)init {
    if (self = [super init]) {
        _wrappers = [NSMutableDictionary new];
        _reusableWrappers = [DFReusablePool new];
    }
    return self;
}

- (DFTaskWrapper *)addHandler:(id<DFTaskHandling>)handler withKey:(id<NSCopying>)key {
    DFTaskWrapper *wrapper = [_wrappers objectForKey:key];
    if (!wrapper) {
        return nil;
    }
    [wrapper.handlers addObject:handler];
    return wrapper;
}

- (DFTaskWrapper *)addTask:(DFTask *)task withKey:(id<NSCopying>)key handler:(id<DFTaskHandling>)handler {
    DFTaskWrapper *wrapper = [_reusableWrappers dequeueObject];
    if (wrapper) {
        wrapper.task = task;
        [wrapper.handlers addObject:handler];
    } else {
        wrapper = [[DFTaskWrapper alloc] initWithTask:task handler:handler];
    }
    __weak DFTaskMultiplexer *weakSelf = self;
    __weak DFTaskWrapper *weakWrapper = wrapper;
    id<NSCopying> keyCopy = [key copyWithZone:nil];
    [wrapper.task setCompletion:^(DFTask *task) {
        [weakSelf _handleTaskCompletion:task wrapper:weakWrapper key:keyCopy];
    }];
    
    [_wrappers setObject:wrapper forKey:key];
    return wrapper;
}

- (DFTaskWrapper *)removeHandler:(id<DFTaskHandling>)handler withKey:(id<NSCopying>)key {
    if (!handler || !key) {
        return nil;
    }
    DFTaskWrapper *wrapper = [_wrappers objectForKey:key];
    if (!wrapper) {
        return nil;
    }
    [wrapper.handlers removeObject:handler];
    return wrapper;
}

- (void)removeTaskWithKey:(id<NSCopying>)key {
    if (!key) {
        return;
    }
    DFTaskWrapper *wrapper = [_wrappers objectForKey:key];
    if (!wrapper) {
        return;
    }
    [wrapper.task setCompletion:nil];
    [_wrappers removeObjectForKey:key];
    [_reusableWrappers enqueueObject:wrapper];
}

- (void)_handleTaskCompletion:(DFTask *)task wrapper:(DFTaskWrapper *)wrapper key:(id<NSCopying>)key {
    for (id<DFTaskHandling> handler in wrapper.handlers) {
        [handler handleTaskCompletion:task];
    }
    [_wrappers removeObjectForKey:key];
    [_reusableWrappers enqueueObject:wrapper];
}

@end


@implementation DFTaskHandler

+ (instancetype)handlerWithCompletion:(DFTaskCompletion)completion {
    DFTaskHandler *handler = [DFTaskHandler new];
    handler.completion = completion;
    return handler;
}

- (void)handleTaskCompletion:(DFTask *)task {
    if (_completion) {
        _completion(task);
    }
}

@end
