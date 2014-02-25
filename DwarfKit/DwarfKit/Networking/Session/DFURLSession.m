/*
 The MIT License (MIT)
 
 Copyright (c) 2013 Alexander Grebenyuk (github.com/kean).
 
 Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:
 
 The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.
 
 THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
 */

#import "DFURLReachabilityManager.h"
#import "DFURLResponseDeserializer.h"
#import "DFURLSession.h"
#import "DFURLSessionHTTPRequest.h"

@implementation DFURLSession {
    NSMutableArray *_tasks;
    NSRecursiveLock *_lock;
}

+ (void)initialize {
    [[DFURLReachabilityManager shared] startMonitoring];
}

- (id)initWithQueue:(NSOperationQueue *)queue taskConfiguration:(DFURLSessionTaskConfiguration *)taskConfiguration requestConstructor:(id<DFURLRequestConstructing>)requestConstructor {
    if (self = [super init]) {
        _lock = [NSRecursiveLock new];
        _tasks = [NSMutableArray new];
        _queue = queue;
        _taskConfiguration = taskConfiguration;
        _requestConstructor = requestConstructor;
    }
    return self;
}

- (id)init {
    NSOperationQueue *queue = [NSOperationQueue new];
    queue.maxConcurrentOperationCount = 8;
    return [self initWithQueue:queue taskConfiguration:nil requestConstructor:nil];
}

- (DFURLSessionTask *)taskWithRequest:(id<DFURLSessionRequest>)request handler:(id)handler success:(DFURLSessionSuccessBlock)success failure:(DFURLSessionFailureBlock)failure {
    DFURLSessionTask *task = [[DFURLSessionTask alloc] initWithSession:self request:request configuration:_taskConfiguration];
    if (handler) {
        [task addHandler:handler success:success failure:failure];
    }
    [task run];
    [self lock];
    [_tasks addObject:task];
    [self unlock];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(_sessionTaskDidFailAttempt:) name:DFURLSessionTaskDidFailAttemptNotification object:task];
    [task addObserver:self forKeyPath:@"state" options:kNilOptions context:nil];
    return task;
}

- (DFURLSessionTask *)taskWithRequest:(id<DFURLSessionRequest>)request success:(DFURLSessionSuccessBlock)success failure:(DFURLSessionFailureBlock)failure {
    return [self taskWithRequest:request handler:self success:success failure:failure];
}

- (DFURLSessionTask *)taskWithRequest:(id<DFURLSessionRequest>)request {
    return [self taskWithRequest:request handler:nil success:nil failure:nil];
}

#pragma mark - <DFURLSession>

- (DFURLConnectionOperation *)connectionOperationForSessionTask:(DFURLSessionTask *)task {
    DFURLConnectionOperation *connectionOperation = [[DFURLConnectionOperation alloc] initWithSessionRequest:task.request];
    [_queue addOperation:connectionOperation];
    return connectionOperation;
}

#pragma mark - DFURLSessionTask Notifications

- (void)_sessionTaskDidFailAttempt:(NSNotification *)notification {
    DFURLSessionTask *task = notification.object;
    if ([_delegate respondsToSelector:@selector(session:didEncounterError:withTask:)]) {
        [_delegate session:self didEncounterError:task.error withTask:task];
    }
}

#pragma mark - Managing Tasks

- (NSArray *)tasks {
    NSArray *tasks;
    [self lock];
    tasks = [_tasks copy];
    [self unlock];
    return tasks;
}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context {
    if ([object isKindOfClass:[DFURLSessionTask class]] && [keyPath isEqualToString:@"state"]) {
        DFURLSessionTask *task = object;
        if ([DFURLSessionTask isStateFinal:task.state]) {
            [self lock];
            [_tasks removeObject:task];
            [self unlock];
            [task removeObserver:self forKeyPath:@"state"];
        }
    }
}

- (DFURLSessionTask *)taskPassingTest:(BOOL (^)(DFURLSessionTask *task))test {
    if (!test) {
        return nil;
    }
    DFURLSessionTask *task;
    [self lock];
    NSUInteger index = [_tasks indexOfObjectPassingTest:^BOOL(id obj, NSUInteger idx, BOOL *stop) {
        return test(obj);
    }];
    task = index != NSNotFound ? _tasks[index] : nil;
    [self unlock];
    return task;
}

#pragma mark - <NSLocking>

- (void)lock {
    [_lock lock];
}

- (void)unlock {
    [_lock unlock];
}

@end

@implementation DFURLSession (HTTP)

- (DFURLHTTPRequestConstructor *)HTTPRequestConstructor {
    if ([_requestConstructor isKindOfClass:[DFURLHTTPRequestConstructor class]]) {
        return (id)_requestConstructor;
    }
    return nil;
}

- (DFURLSessionHTTPRequest *)HTTPRequestWithRequest:(NSURLRequest *)request {
    DFURLSessionHTTPRequest *r = [[DFURLSessionHTTPRequest alloc] initWithRequest:request];
    r.constructor = [[self HTTPRequestConstructor] copy];
    return r;
}

@end
