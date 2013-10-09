/*
 The MIT License (MIT)
 
 Copyright (c) 2013 Alexander Grebenyuk (github.com/kean).
 
 Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:
 
 The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.
 
 THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
 */

#import "DFTask+DFTaskPrivate.h"
#import "DFTask.h"
#import "DFTaskQueue.h"
#import "dwarf_private.h"


@interface DFTaskQueue() <_DFTaskDelegate>

@end


@implementation DFTaskQueue {
    NSMutableOrderedSet *_tasks;
    NSUInteger _executingTaskCount;
}

- (id)init {
    if (self = [super init]) {
        _tasks = [NSMutableOrderedSet new];
    }
    return self;
}

- (void)_setDefaults {
    _maxConcurrentTaskCount = 3;
}

- (void)addTask:(DFTask *)task {
    [task _setImplDelegate:self];
    [_tasks addObject:task];
    [self _executeTasks];
}

- (NSOrderedSet *)tasks {
    return _tasks;
}

#pragma mark - Task Execution

- (void)_executeTasks {
    if (_suspended) {
        return;
    }
    DFTask *task;
    while (_executingTaskCount < _maxConcurrentTaskCount &&
           (task = [self _taskToExecute])) {
        _executingTaskCount++;
        [task _setExecuting:YES];
        dispatch_async(dispatch_get_global_queue(task.priority, 0), ^{
            [task execute];
        });
    }
}

- (DFTask *)_taskToExecute {
    for (DFTask *task in _tasks) {
        if (!task.isExecuting) {
            return task;
        }
    }
    return nil;
}

#pragma mark - _DFTaskDelegate

- (void)_taskDidFinish:(DFTask *)task {
    dispatch_async(dispatch_get_main_queue(), ^{
        _executingTaskCount--;
        [_tasks removeObject:task];
        [self _executeTasks];
        
        if (task.completion) {
            task.completion(task);
        }
    });
}

#pragma mark - Suspension

- (void)setSuspended:(BOOL)suspended {
    if (_suspended != suspended) {
        _suspended = suspended;
        if (!_suspended) {
            [self _executeTasks];
        }
    }
}

#pragma mark - Task Cancellation

- (void)cancelAllTasks {
    for (DFTask *task in _tasks) {
        [task cancel];
    }
}

@end
