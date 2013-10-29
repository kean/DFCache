/*
 The MIT License (MIT)
 
 Copyright (c) 2013 Alexander Grebenyuk (github.com/kean).
 
 Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:
 
 The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.
 
 THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
 */

#import "DFProcessingCenter.h"
#import "DFTaskMultiplexer.h"


@implementation DFProcessingCenter {
    DFTaskMultiplexer *_multiplexer;
    NSUInteger (^_costBlock)(id);
}

- (id)init {
    if (self = [super init]) {
        _multiplexer = [DFTaskMultiplexer new];
        _queue = [DFTaskQueue new];
        _queue.maxConcurrentTaskCount = 2;
        _cache = [NSCache new];
    }
    return self;
}

- (void)setCostBlock:(NSUInteger (^)(id))cost {
    if (cost) {
        _costBlock = [cost copy];
    }
}

#pragma mark - Requests

- (DFProcessingTask *)processInput:(id)input key:(NSString *)key handler:(DFTaskHandler *)handler usingBlock:(id (^)(id))processingBlock {
    if (!key || !input || !processingBlock) {
        return nil;
    }
    DFTaskWrapper *wrapper = [_multiplexer addHandler:handler withKey:key];
    if (wrapper) {
        return (id)wrapper.task;
    }
    DFProcessingTask *task = [[DFProcessingTask alloc] initWithInput:input key:key processingBlock:processingBlock];
    [_multiplexer addTask:task withKey:key handler:handler];
    [_queue addTask:task];
    return task;
}

- (void)cancelProcessingWithKey:(NSString *)key handler:(DFTaskHandler *)handler {
    if (!handler || !key) {
        return;
    }
    DFTaskWrapper *wrapper = [_multiplexer removeHandler:handler withKey:key];
    if (wrapper.handlers.count == 0) {
        [wrapper.task cancel];
        [_multiplexer removeTaskWithKey:key];
    }
}

#pragma mark - DFProcessingTaskCaching

- (void)storeObject:(id)object forKey:(id<NSCopying>)key {
    if (object && key) {
        NSUInteger cost = _costBlock ? _costBlock(object) : 0;
        [_cache setObject:object forKey:key cost:cost];
    }
}

- (id)cachedObjectForKey:(id<NSCopying>)key {
    return [_cache objectForKey:key];
}

@end
