/*
 The MIT License (MIT)
 
 Copyright (c) 2013 Alexander Grebenyuk (github.com/kean).
 
 Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:
 
 The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.
 
 THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
 */

#import "DFReusablePool.h"
#import "DFTaskQueue.h"


@protocol DFTaskHandler

- (void)handleTaskCompletion:(DFTask *)task;

@end


@interface DFTaskWrapper : NSObject <DFReusable>

@property (nonatomic) NSString *token;
@property (nonatomic) DFTask *task;
@property (nonatomic) NSMutableArray *handlers;

- (id)initWithToken:(NSString *)token task:(DFTask *)task handler:(id)handler;

@end


/*! Task multiplexing is a simple model built on top of DFTask and DFTaskQueue that allows multiple requests with the same token to be handled by a single task.
 @discussion Multiplexing and demultiplexing is implemented by wrapping tasks into instances of DFTaskWrapper class having array of handlers (objects conforming to <DFTaskHandler> protocol). DFTaskMultiplexer provides it's own <DFTaskHandler> implementation (DFTaskHandler class) with a single completion block (which is the same as the original DFTaskCompletion block of DFTask).
 */
@interface DFTaskMultiplexer : NSObject

@property (nonatomic, readonly) DFTaskQueue *queue;

- (id)initWithQueue:(DFTaskQueue *)queue;

- (DFTaskWrapper *)addHandler:(id<DFTaskHandler>)handler withToken:(NSString *)token;
- (DFTaskWrapper *)addTask:(DFTask *)task withToken:(NSString *)token handler:(id<DFTaskHandler>)handler;
- (DFTaskWrapper *)removeHandler:(id<DFTaskHandler>)handler withToken:(NSString *)token;
- (void)cancelTaskWithToken:(NSString *)token;

@end


/*! Basic <DFTaskHandler> implementation with a single completion block (which is the same as the original DFTaskCompletion block of DFTask).
 */
@interface DFTaskHandler : NSObject <DFTaskHandler>

@property (nonatomic, copy) DFTaskCompletion completion;

+ (instancetype)handlerWithSuccess:(DFTaskCompletion)completion;

@end
