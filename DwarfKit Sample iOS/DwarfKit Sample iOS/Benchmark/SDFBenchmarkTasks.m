/*
 The MIT License (MIT)
 
 Copyright (c) 2013 Alexander Grebenyuk (github.com/kean).
 
 Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:
 
 The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.
 
 THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
 */

#import "DFBenchmark.h"
#import "DFTask.h"
#import "DFTaskQueue.h"
#import "DFTesting.h"
#import "SDFBenchmarkTasks.h"

@implementation SDFBenchmarkTasks

- (void)run {
    NSLog(@"Benchmark: NSOperation and DFTask");
    
    [self _benchmarkInitializtion];
    [self _benchamarkAddToQueue];
    [self _benchmarkGetTasks];
    [self _benchmarkCancel];
}

- (void)_benchmarkInitializtion {
    uint32_t count = 10000;
    NSLog(@"Benchmark (NSOperation): [NSOperation new]");
    dwarf_benchmark_loop(count, YES, ^{
        __attribute__((unused)) NSOperation *operation = [NSOperation new];
    });
    NSLog(@"Benchmark (DFTask): [DFTask new]");
    dwarf_benchmark_loop(count, YES, ^{
        __attribute__((unused)) DFTask *task = [DFTask new];
    });
}

- (void)_benchamarkAddToQueue {
    uint32_t count = 10000;
    NSLog(@"Benchmark (NSOperation): [queue addOperationWithBlock:]");
    NSOperationQueue *queue = [NSOperationQueue new];
    dwarf_benchmark_loop(count, YES, ^{
        [queue addOperationWithBlock:^{
            // Do nothing
        }];
    });
    
    NSLog(@"Benchmark (DFTask): [queue addTaskWithBlock:]");
    DFTaskQueue *taskQueue = [DFTaskQueue new];
    taskQueue.maxConcurrentTaskCount = 5;
    dwarf_benchmark_loop(count, YES, ^{
        [taskQueue addTaskWithBlock:^(DFTask *task) {
            // Do nothing
        }];
    });
}

- (void)_benchmarkGetTasks {
    uint32_t count = 10000;
    NSUInteger taskCount = 300;
    
    NSLog(@"Benchmark (NSOperation): [queue operations]");
    NSOperationQueue *queue = [NSOperationQueue new];
    for (NSUInteger i = 0; i < taskCount; i++) {
        [queue addOperationWithBlock:^{
            // Do nothing
        }];
    }
    dwarf_benchmark_loop(count, YES, ^{
        __attribute__((unused)) NSArray *operations = [queue operations];
    });
    
    NSLog(@"Benchmark (DFTask): [queue tasks]");
    DFTaskQueue *taskQueue = [DFTaskQueue new];
    taskQueue.maxConcurrentTaskCount = 5;
    for (NSUInteger i = 0; i < taskCount; i++) {
        [taskQueue addTaskWithBlock:^(DFTask *task) {
            // Do nothing
        }];
    }
    dwarf_benchmark_loop(count, YES, ^{
        __attribute__((unused)) NSOrderedSet *tasks = [taskQueue tasks];
    });
}

- (void)_benchmarkCancel {
    uint32_t count = 10000;
    
    NSLog(@"Benchmark (NSOperation): [operation cancel]");
    NSOperationQueue *queue = [NSOperationQueue new];
    [queue setSuspended:YES];
    NSOperation *operation = [NSBlockOperation blockOperationWithBlock:^{
        // Do nothing
    }];
    dwarf_benchmark_loop(count, YES, ^{
        [operation cancel];
    });
    
    NSLog(@"Benchmark (DFTask): [task cancel]");
    DFTaskQueue *taskQueue = [DFTaskQueue new];
    taskQueue.suspended = YES;
    DFTaskWithBlock *task = [[DFTaskWithBlock alloc] initWithBlock:^(DFTask *task) {
        // Do nothing
    }];
    dwarf_benchmark_loop(count, YES, ^{
        [task cancel];
    });
}

@end
