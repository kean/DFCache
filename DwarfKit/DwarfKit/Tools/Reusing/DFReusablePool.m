/*
 The MIT License (MIT)
 
 Copyright (c) 2013 Alexander Grebenyuk (github.com/kean).
 
 Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:
 
 The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.
 
 THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
 */

#import "DFReusablePool.h"

@interface _DFReusablePool : NSObject

- (void)enqueueObject:(id<DFReusable>)object;
- (id<DFReusable>)dequeueObject;

@end


@implementation DFReusablePool {
    _DFReusablePool *_anonymousPool;
    NSMutableDictionary *_pools;
}

- (id)init {
    if (self = [super init]) {
        _pools = [NSMutableDictionary new];
    }
    return self;
}

- (id<DFReusable>)dequeueObject {
    return [_anonymousPool dequeueObject];
}

- (id<DFReusable>)dequeueObjectWithIdentifier:(NSString *)identifier {
    return [[self _poolWithIdentifier:identifier] dequeueObject];
}

- (void)enqueueObject:(id<DFReusable>)object {
    [_anonymousPool enqueueObject:object];
}

- (void)enqueueObject:(id<DFReusable>)object withIdentifier:(NSString *)identifier {
    [[self _poolWithIdentifier:identifier] enqueueObject:object];
}

- (_DFReusablePool *)_poolWithIdentifier:(NSString *)identifier {
    _DFReusablePool *pool = [_pools objectForKey:identifier];
    if (pool) {
        return pool;
    }
    pool = [_DFReusablePool new];
    [_pools setObject:pool forKey:identifier];
    return pool;
}

@end


@implementation _DFReusablePool {
    NSMutableArray *_pool;
}

- (id)init {
    if (self = [super init]) {
        _pool = [NSMutableArray new];
    }
    return self;
}

- (void)enqueueObject:(id<DFReusable>)object {
    if (object) {
        [_pool addObject:object];
        [object prepareForReuse];
    }
}

- (id<DFReusable>)dequeueObject {
    id<DFReusable> object = [_pool lastObject];
    if (object) {
        [_pool removeLastObject];
    }
    return object;
}

@end
