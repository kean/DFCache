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

- (id)initWithToken:(NSString *)token task:(DFTask *)task handler:(id)handler {
    if (self = [super init]) {
        _token = token;
        _task = task;
        _handlers = [NSMutableArray arrayWithObject:handler];
    }
    return self;
}

- (void)prepareForReuse {
    _token = nil;
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
        _queue = [DFTaskQueue new];
    }
    return self;
}

- (DFTask *)addHandler:(id)handler withToken:(NSString *)token {
    DFTaskWrapper *wrapper = [_wrappers objectForKey:token];
    if (wrapper) {
        [wrapper.handlers addObject:handler];
        return wrapper.task;
    }
    return nil;
}

- (DFTaskWrapper *)dequeueReusableWrapper {
    return [_reusableWrappers dequeueObject];
}

- (DFTaskWrapper *)addTask:(DFTask *)task withToken:(NSString *)token handler:(id)handler {
    DFTaskWrapper *wrapper = [_reusableWrappers dequeueObject];
    if (wrapper) {
        wrapper.task = task;
        wrapper.token = token;
        [wrapper.handlers addObject:handler];
    } else {
        wrapper = [[DFTaskWrapper alloc] initWithToken:token task:task handler:handler];
    }
    __weak DFTaskWrapper *weakWrapper = wrapper;
    [wrapper.task setCompletion:^(DFTask *task) {
        [self _handleTaskCompletion:weakWrapper];
    }];
    [_wrappers setObject:wrapper forKey:token];
    [_queue addTask:wrapper.task];
    return wrapper;
}

- (DFTaskWrapper *)removeHandler:(id)handler withToken:(NSString *)token {
    if (!handler || !token) {
        return nil;
    }
    DFTaskWrapper *wrapper = [_wrappers objectForKey:token];
    if (!wrapper) {
        return nil;
    }
    [wrapper.handlers removeObject:handler];
    return wrapper;
}

- (void)cancelTaskWithToken:(NSString *)token {
    DFTaskWrapper *wrapper = [_wrappers objectForKey:token];
    [wrapper.task cancel];
    [wrapper.task setCompletion:nil];
    [_wrappers removeObjectForKey:token];
    [_reusableWrappers enqueueObject:wrapper];
}

- (void)_handleTaskCompletion:(DFTaskWrapper *)wrapper {
    if (wrapper.task.isCancelled) {
        return;
    }
    [_delegate handleTaskCompletion:wrapper];
    [_wrappers removeObjectForKey:wrapper.token];
    [_reusableWrappers enqueueObject:wrapper];
}

@end
