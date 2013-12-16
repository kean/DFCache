/*
 The MIT License (MIT)
 
 Copyright (c) 2013 Alexander Grebenyuk (github.com/kean).
 
 Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:
 
 The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.
 
 THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
 */

#import "DFTaskMultiplexer.h"
#import "DFTaskQueue.h"
#import "DFTesting.h"
#import <XCTest/XCTest.h>


@interface TDFTasks : XCTestCase

@end


@implementation TDFTasks

- (void)testTaskWithBlockExecution {
    DFTaskQueue *queue = [DFTaskQueue new];
    __block BOOL isWorkDone = NO;
    DFTaskWithBlock *task = [[DFTaskWithBlock alloc] initWithBlock:^(DFTask *task){
        isWorkDone = YES;
    }];
    __block BOOL isWaiting = YES;
    [task setCompletion:^(DFTask *task) {
        XCTAssertTrue(isWorkDone);
        isWaiting = NO;
    }];
    [queue addTask:task];
    DWARF_TEST_WAIT_WHILE(isWaiting, 3.f);
}

- (void)testTaskStatesAfterNormalExecution {
    DFTaskQueue *queue = [DFTaskQueue new];
    DFTaskWithBlock *task = [[DFTaskWithBlock alloc] initWithBlock:nil];
    __block BOOL isWaiting = YES;
    [task setCompletion:^(DFTask *task) {
        XCTAssertTrue([task isExecuting]);
        XCTAssertTrue([task isFinished]);
        XCTAssertFalse([task isCancelled]);
        isWaiting = NO;
    }];
    [queue addTask:task];
    DWARF_TEST_WAIT_WHILE(isWaiting, 3.f);
}

- (void)testTaskCancellation {
    DFTaskQueue *queue = [DFTaskQueue new];
    __block BOOL isWorkDone = NO;
    DFTaskWithBlock *task = [[DFTaskWithBlock alloc] initWithBlock:^(DFTask *task) {
        if ([task isCancelled]) {
            [task finish];
            return;
        }
        isWorkDone = YES;
    }];
    __block BOOL isWaiting = YES;
    [task setCompletion:^(DFTask *task) {
        XCTAssertFalse(isWorkDone);
        XCTAssertTrue([task isFinished]);
        XCTAssertTrue([task isExecuting]);
        XCTAssertTrue([task isCancelled]);
        isWaiting = NO;
    }];
    [queue addTask:task];
#warning race condition, task may finish executing before cacnel is called
    [task cancel];
    DWARF_TEST_WAIT_WHILE(isWaiting, 3.f);
}

- (void)testDependencies {
    DFTaskQueue *queue = [DFTaskQueue new];
    queue.maxConcurrentTaskCount = 10;
    __block BOOL isFirstTaskRun = NO;
    __block BOOL isWaiting = YES;
    DFTaskWithBlock *task1 = [[DFTaskWithBlock alloc] initWithBlock:^(DFTask *task) {
        isFirstTaskRun = YES;
        isWaiting = NO;
        DFTask *dependency = [task.dependencies firstObject];
        XCTAssertTrue([dependency isFinished]);
        XCTAssertTrue(dependency.priority == 15); // Check "result" of task 2.
    }];
    DFTaskWithBlock *task2 = [[DFTaskWithBlock alloc] initWithBlock:^(DFTask *task) {
        XCTAssertFalse(isFirstTaskRun);
        task.priority = 15;
        sleep(0.25);
    }];
    [task1 addDependency:task2];
    
    [queue addTask:task1];
    [queue addTask:task2];
    DWARF_TEST_WAIT_WHILE(isWaiting, 3.f);
}

- (void)testDependenciesOnDifferentQueues {
    DFTaskQueue *queue1 = [DFTaskQueue new];
    DFTaskQueue *queue2 = [DFTaskQueue new];

    __block BOOL isFirstTaskRun = NO;
    __block BOOL isWaiting = YES;
    DFTaskWithBlock *task1 = [[DFTaskWithBlock alloc] initWithBlock:^(DFTask *task) {
        isFirstTaskRun = YES;
        isWaiting = NO;
        DFTask *dependency = [task.dependencies firstObject];
        XCTAssertTrue([dependency isFinished]);
        XCTAssertTrue(dependency.priority == 15); // Check "result" of task 2.
    }];
    DFTaskWithBlock *task2 = [[DFTaskWithBlock alloc] initWithBlock:^(DFTask *task) {
        XCTAssertFalse(isFirstTaskRun);
        task.priority = 15;
        sleep(0.25);
    }];
    [task1 addDependency:task2];

    [queue1 addTask:task1];
    [queue2 addTask:task2];
    DWARF_TEST_WAIT_WHILE(isWaiting, 3.f);
}

@end
