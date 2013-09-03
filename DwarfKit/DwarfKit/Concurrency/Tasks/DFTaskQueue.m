//
//  DFTaskQueue.m
//  Dwarf
//
//  Created by Alexander Grebenyuk on 06.08.13.
//  Copyright (c) 2013 Alexander Grebenyuk. All rights reserved.
//

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

#pragma mark - Task Execution

- (void)_executeTasks {
    if (_paused) {
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

- (void)setPaused:(BOOL)paused {
    dispatch_sync(_syncQueue, ^{
        if (_paused != paused) {
            _paused = paused;
            if (!_paused) {
                [self _executeTasks];
            }
        }
    });
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
