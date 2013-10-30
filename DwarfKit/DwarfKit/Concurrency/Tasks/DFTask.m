/*
 The MIT License (MIT)
 
 Copyright (c) 2013 Alexander Grebenyuk (github.com/kean).
 
 Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:
 
 The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.
 
 THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
 */

#import "DFTask.h"
#import "DFTask+DFTaskPrivate.h"


@implementation DFTask {
    __weak id<_DFTaskDelegate> _impl_delegate;
}

- (id)init {
    if (self = [super init]) {
        _priority = DISPATCH_QUEUE_PRIORITY_DEFAULT;
    }
    return self;
}

- (BOOL)isEqual:(id)object {
    return self == object;
}

- (void)execute {
    [self doesNotRecognizeSelector:_cmd];
}

- (void)finish {
    [_impl_delegate _taskDidFinish:self];
}

- (void)cancel {
    _isCancelled = YES;
}

#pragma mark - DFTask+DFTaskPrivate

- (void)_setImplDelegate:(id<_DFTaskDelegate>)delegate {
    _impl_delegate = delegate;
}

- (void)_setExecuting:(BOOL)executing {
    _isExecuting = executing;
}

- (void)_setFinished:(BOOL)finished {
    _isFinished = finished;
}

@end


@implementation DFTaskWithBlock {
    void (^_block)(DFTask *);
}

- (id)initWithBlock:(void (^)(DFTask *))block {
    if (self = [super init]) {
        _block = [block copy];
    }
    return self;
}

- (void)execute {
    if (_block) {
        _block(self);
    }
    [self finish];
}

@end
