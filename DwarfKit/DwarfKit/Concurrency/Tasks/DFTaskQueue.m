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
    dispatch_queue_t _syncQueue;
    NSMutableOrderedSet *_tasks;
    NSUInteger _executingTaskCount;
    BOOL _suspended;
}

- (void)dealloc {
    DWARF_DISPATCH_RELEASE(_syncQueue);
}

- (id)init {
    if (self = [super init]) {
        _syncQueue = dispatch_queue_create("dwarf.task.queue", DISPATCH_QUEUE_SERIAL);
        _tasks = [NSMutableOrderedSet new];
    }
    return self;
}

- (void)_setDefaults {
    _maxConcurrentTaskCount = 3;
}

- (void)addTask:(DFTask *)task {
    dispatch_sync(_syncQueue, ^{
        [task _setImplDelegate:self];
        [_tasks addObject:task];
        [self _executeTasks];
    });
}

- (NSOrderedSet *)tasks {
    __block NSOrderedSet *tasks;
    dispatch_sync(_syncQueue, ^{
        tasks = [_tasks copy];
    });
    return tasks;
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
    dispatch_sync(_syncQueue, ^{
        if (task.isExecuting) {
            _executingTaskCount--;
            [task _setExecuting:NO];
            [task _setFinished:YES];
            [_tasks removeObject:task];
            [self _executeTasks];
            dispatch_async(dispatch_get_main_queue(), ^{
                if (task.completionBlock) {
                    task.completionBlock(task);
                }
            });
        }
    });
}

#pragma mark - Pause

- (void)setSuspended:(BOOL)suspended {
    dispatch_sync(_syncQueue, ^{
        if (_suspended != suspended) {
            _suspended = suspended;
            if (!_suspended) {
                [self _executeTasks];
            }
        }
    });
}

- (BOOL)isSuspended {
    __block BOOL suspended;
    dispatch_sync(_syncQueue, ^{
        suspended = _suspended;
    });
    return suspended;
}

#pragma mark - Task Cancellation

- (void)cancelAllTasks {
    dispatch_sync(_syncQueue, ^{
        for (DFTask *task in _tasks) {
            [task cancel];
        }
    });
}

@end
