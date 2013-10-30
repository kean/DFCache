/*
 The MIT License (MIT)
 
 Copyright (c) 2013 Alexander Grebenyuk (github.com/kean).
 
 Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:
 
 The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.
 
 THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
 */

@class DFTask;

typedef void (^DFTaskCompletion)(DFTask *task);

/*! The DFTask is an abstract class that is used to encapsulate the code and data associated with a single task. This class is used by either subclassing and providing your own - (void)execute implementation or by using predifined DFTaskWithBlock class.
 @discussion Task is a single-shot object, it cannot be reused. Tasks are executed by adding them a queue (an instance of DFTaskQueue class). Queue executes task by calling it's - (void)execute method on the global GCD queue with a priority specified by DFTask priority property. There is no way to execute task manually without a queue.
 @discussion Tasks semantics are fairly simple. There is no need to manually manage states. All you need to do is implement - (void)execute method and call - (void)finish when the work is done. You might also want to define getter methods to access the resulting data from the task. Task should respond to the cancellation by either overriding - (void)cancel method or quering - (BOOL)isCancelled periodically while executing. All you need to do is call - (void)finish.
 @discussion Dependencies are a convenient way to execute tasks in a specific order and to combine the results of the finished tasks. By default task not considered to be ready to execute until all of the tasks it depends on have finished executing. Task holds strong references to the tasks it depends on. You may also introduce you own isReady implementation, add and remove dependencies after task has been added to the queue and more. Dependencies provide an absolute execution order for tasks, even if those tasks are located in different queues.
 @warning DFTask is not multhithread-aware (in order to get best performance out of it). If you intend to call - (void)cancel method you must call it from the main thread.
 */
@interface DFTask : NSObject

@property (nonatomic, readonly) BOOL isExecuting;
@property (nonatomic, readonly) BOOL isFinished;
@property (nonatomic, readonly) BOOL isCancelled;
@property (nonatomic, readonly) BOOL isReady;

@property (nonatomic, copy) DFTaskCompletion completion;
@property (nonatomic) dispatch_queue_priority_t priority;
@property (nonatomic, readonly) NSArray *dependencies;

- (void)execute;

- (void)finish;
- (void)cancel;

- (void)setCompletion:(DFTaskCompletion)completion;

- (void)addDependency:(DFTask *)task;
- (void)removeDependency:(DFTask *)task;

@end


@interface DFTaskWithBlock : DFTask

- (id)initWithBlock:(void (^)(DFTask *task))block;

@end
