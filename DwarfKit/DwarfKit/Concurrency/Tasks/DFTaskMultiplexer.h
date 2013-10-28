/*
 The MIT License (MIT)
 
 Copyright (c) 2013 Alexander Grebenyuk (github.com/kean).
 
 Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:
 
 The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.
 
 THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
 */

#import "DFReusablePool.h"
#import "DFTaskQueue.h"


@protocol DFTaskHandling

- (void)handleTaskCompletion:(DFTask *)task;

@end


@interface DFTaskWrapper : NSObject <DFReusable>

@property (nonatomic) DFTask *task;
@property (nonatomic) NSMutableArray *handlers;

@end


/*! Task multiplexing is a simple model built on top of DFTask that allows multiple requests with the same key to be handled by a single task.

 @discussion Multiplexing is a process of adding handlers to a task. Demultiplexing is a process of calling all the handlers when the task is complete. Multiplexing and demultiplexing is implemented using DFTaskWrapper class. Each wrapper stores a task and an array of handlers conforming to <DFTaskHandling> protocol. Most of the time it is sufficient to use predefined DFTaskHandler class as a handler.
 */
@interface DFTaskMultiplexer : NSObject

@property (nonatomic, readonly) DFTaskQueue *queue;

/*! Returns a pointer to the actual wrappers dictionary.
 */
@property (nonatomic, readonly) NSMutableDictionary *wrappers;

- (id)initWithQueue:(DFTaskQueue *)queue;

/*! Adds handler to the wrapper with the provided key. Returns the wrapper if it exists.
 */
- (DFTaskWrapper *)addHandler:(id<DFTaskHandling>)handler withKey:(id<NSCopying>)key;

/*! Adds task with the provided key and handler. Returns created wrapper.
 */
- (DFTaskWrapper *)addTask:(DFTask *)task withKey:(id<NSCopying>)key handler:(id<DFTaskHandling>)handler;

/*! Removes handler from the wrapper with the provided key. Returns the wrapper if it exists.
 */
- (DFTaskWrapper *)removeHandler:(id<DFTaskHandling>)handler withKey:(id<NSCopying>)key;

@end


/*! Basic <DFTaskHandling> implementation with a single completion block (which is the same as the original DFTaskCompletion block of DFTask).
 */
@interface DFTaskHandler : NSObject <DFTaskHandling>

@property (nonatomic, copy) DFTaskCompletion completion;

+ (instancetype)handlerWithCompletion:(DFTaskCompletion)completion;

@end
