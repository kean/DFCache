/*
 The MIT License (MIT)
 
 Copyright (c) 2013 Alexander Grebenyuk (github.com/kean).
 
 Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:
 
 The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.
 
 THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
 */

#import "DFURLReachabilityManager.h"
#import "DFURLConnectionOperation.h"
#import "DFURLSessionTask.h"
#import "NSTimer+Blocks.h"


NSString *const DFURLSessionTaskDidFailAttemptNotification = @"DFURLSessionTaskDidFailAttemptNotification";


#pragma mark - _DFURLSessionTaskHandler

@interface _DFURLSessionTaskHandler : NSObject <NSCopying>

@property (nonatomic, readonly) DFURLSessionSuccessBlock success;
@property (nonatomic, readonly) DFURLSessionFailureBlock failure;
@property (nonatomic, readonly) DFURLSessionProgressBlock progress;

- (id)initWithSuccess:(DFURLSessionSuccessBlock)success failure:(DFURLSessionFailureBlock)failure progress:(DFURLSessionProgressBlock)progress;

@end

@implementation _DFURLSessionTaskHandler

- (id)initWithSuccess:(DFURLSessionSuccessBlock)success failure:(DFURLSessionFailureBlock)failure progress:(DFURLSessionProgressBlock)progress {
    if (self = [super init]) {
        _success = [success copy];
        _failure = [failure copy];
        _progress = [progress copy];
    }
    return self;
}

- (id)copyWithZone:(NSZone *)zone {
    return [[_DFURLSessionTaskHandler alloc] initWithSuccess:_success failure:_failure progress:_progress];
}

@end


#pragma mark - DFURLSessionTask

@implementation DFURLSessionTask {
    DFURLConnectionOperation *_connectionOperation;
    NSMapTable *_handlers;
    NSRecursiveLock *_lock;
    
    // Retry
    DFURLDelay *_retryDelay;
    NSUInteger _retryAttemptCount;
    NSTimer *__weak _retryTimer;
}

@synthesize configuration = _conf;

- (void)dealloc {
    [_retryTimer invalidate];
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (id)initWithSession:(id<DFURLSession>)session request:(id<DFURLSessionRequest>)request configuration:(DFURLSessionTaskConfiguration *)configuration {
    if (self = [super init]) {
        _lock = [NSRecursiveLock new];
        _session = session;
        _request = request;
        _conf = [configuration copy];
        _handlers = [[NSMapTable alloc] initWithKeyOptions:(NSPointerFunctionsOpaquePersonality | NSPointerFunctionsWeakMemory) valueOptions:NSPointerFunctionsCopyIn capacity:10];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(_networkReachabilityDidChange:) name:DFURLReachabilityDidChangeNotification object:nil];
    }
    return self;
}

- (void)run {
    self.state = DFURLSessionTaskStateRunning;
}

- (void)cancel {
    self.state = DFURLSessionTaskStateCancelled;
}

#pragma mark - States

+ (BOOL)isStateFinal:(DFURLSessionTaskState)state {
    return (state == DFURLSessionTaskStateSucceed ||
            state == DFURLSessionTaskStateFailed ||
            state == DFURLSessionTaskStateCancelled);
}

- (void)setState:(DFURLSessionTaskState)state {
    [self lock];
    if ([self _isAllowedTransitionToState:state]) {
        [self _executeExitActionForState:_state];
        [self _executeTranstionActionFromState:_state toState:state];
        _state = state;
        [self _executeEnterActionForState:_state];
    }
    [self unlock];
}

- (BOOL)_isAllowedTransitionToState:(DFURLSessionTaskState)toState {
    static NSDictionary *transitions; // @{ from : to }
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        transitions =
        @{ @(DFURLSessionTaskStateSuspended) : @[ @(DFURLSessionTaskStateRunning),
                                                  @(DFURLSessionTaskStateCancelled) ],
           @(DFURLSessionTaskStateRunning) : @[ @(DFURLSessionTaskStateSucceed),
                                                @(DFURLSessionTaskStateFailed),
                                                @(DFURLSessionTaskStateCancelled),
                                                @(DFURLSessionTaskStateWaiting) ],
           @(DFURLSessionTaskStateWaiting) : @[ @(DFURLSessionTaskStateRunning),
                                                @(DFURLSessionTaskStateCancelled) ] };
    });
    DFURLSessionTaskState fromState = _state;
    return [transitions[@(fromState)] containsObject:@(toState)];
}

- (void)_executeEnterActionForState:(DFURLSessionTaskState)state {
    if (_state == DFURLSessionTaskStateWaiting) {
        [self _startRetryTimer];
    }
    if (_state == DFURLSessionTaskStateRunning) {
        [self _startConnectionOperation];
    }
    if (_state == DFURLSessionTaskStateFailed) {
        NSMapTable *handlers = [_handlers copy];
        dispatch_async(dispatch_get_main_queue(), ^{
            for (id key in handlers) {
                _DFURLSessionTaskHandler *handler = [handlers objectForKey:key];
                if (handler.failure) {
                    handler.failure(_error, self);
                }
            }
        });
    }
    if (_state == DFURLSessionTaskStateSucceed) {
        NSMapTable *handlers = [_handlers copy];
        dispatch_async(dispatch_get_main_queue(), ^{
            for (id key in handlers) {
                _DFURLSessionTaskHandler *handler = [handlers objectForKey:key];
                if (handler.success) {
                    handler.success(_response, self);
                }
            }
        });
    }
}

- (void)_executeTranstionActionFromState:(DFURLSessionTaskState)fromState toState:(DFURLSessionTaskState)toState {
    if (fromState == DFURLSessionTaskStateRunning &&
        toState == DFURLSessionTaskStateCancelled) {
        [_connectionOperation cancel];
    }
    if (fromState == DFURLSessionTaskStateWaiting &&
        toState == DFURLSessionTaskStateRunning) {
        _retryAttemptCount++;
    }
}

- (void)_executeExitActionForState:(DFURLSessionTaskState)state {
    if (_state == DFURLSessionTaskStateWaiting) {
        [_retryTimer invalidate];
    }
}

#pragma mark - Connection

- (void)_startConnectionOperation {
    _connectionOperation = [_session connectionOperationForSessionTask:self];
    if (!_connectionOperation) {
        self.state = DFURLSessionTaskStateFailed;
        return;
    }
    _connectionOperation.cachingEnabled = _conf.cachingEnabled;
    _connectionOperation.delegate = self;
}

- (void)connectionOperationDidFinish:(DFURLConnectionOperation *)operation {
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        @autoreleasepool {
            [self _connectionOperationDidFinish:operation];
        }
    });
}

- (void)_connectionOperationDidFinish:(DFURLConnectionOperation *)operation {
    NSError *error;
    if (![_conf.deserializer isValidResponse:operation.response task:self error:&error]) {
        _error = error;
        [self _fail];
        return;
    }
    id object = [_conf.deserializer objectFromResponse:operation.response data:operation.responseData task:self error:&error];
    _error = error;
    if (!object) {
        [self _fail];
        return;
    }
    _response = [[DFURLSessionResponse alloc] initWithObject:object response:operation.response data:operation.responseData];
    self.state = DFURLSessionTaskStateSucceed;
}

- (void)connectionOperation:(DFURLConnectionOperation *)operation didFailWithError:(NSError *)error {
    _error = error;
    [self _fail];
}

- (void)_fail {
    [[NSNotificationCenter defaultCenter] postNotificationName:DFURLSessionTaskDidFailAttemptNotification object:self];
    self.state = [self _shouldRetry] ? DFURLSessionTaskStateWaiting : DFURLSessionTaskStateFailed;
}

- (void)connectionOperation:(DFURLConnectionOperation *)operation didUpdateProgress:(DFURLProgress)progress {
    NSMapTable *handlers;
    [self lock];
    handlers = [_handlers copy];
    [self unlock];
    dispatch_async(dispatch_get_main_queue(), ^{
        for (id key in handlers) {
            _DFURLSessionTaskHandler *handler = [handlers objectForKey:key];
            if (handler.progress) {
                handler.progress(progress, self);
            }
        }
    });
}

#pragma mark - Handlers

- (void)addHandler:(id)handler success:(DFURLSessionSuccessBlock)success failure:(DFURLSessionFailureBlock)failure progress:(DFURLSessionProgressBlock)progress {
    [self lock];
    [_handlers setObject:[[_DFURLSessionTaskHandler alloc] initWithSuccess:success failure:failure progress:progress] forKey:handler];
    [self unlock];
}

- (void)addHandler:(id)handler success:(DFURLSessionSuccessBlock)success failure:(DFURLSessionFailureBlock)failure {
    [self addHandler:handler success:success failure:failure progress:nil];
}

- (void)removeHandler:(id)handler {
    [self lock];
    [_handlers removeObjectForKey:handler];
    if (!_handlers.count && _conf.cancelsWhenZeroHandlers) {
        [self cancel];
    }
    [self unlock];
}

#pragma mark - Retry

- (CGFloat)_retryDelay {
    if (!_retryDelay) {
        _retryDelay = [[DFURLDelay alloc] initWithConfiguration:_conf.retryConfiguration.delayConfiguration];
    }
    return _retryDelay.currentDelay;
}

- (BOOL)_shouldRetry {
    if (!_conf.retryConfiguration) {
        return NO;
    }
    NSAssert(_conf.retryConfiguration.shouldRetry, @"Invalid retry configuration (no should retry block)");
    return _conf.retryConfiguration.shouldRetry(_error, _retryAttemptCount, _conf.retryConfiguration, self);
}

- (void)_startRetryTimer {
    DFURLSessionTask *__weak weakSelf = self;
    _retryTimer = [NSTimer scheduledTimerWithTimeInterval:[self _retryDelay] block:^{
        [weakSelf run];
    } userInfo:nil repeats:NO];
}

- (void)_networkReachabilityDidChange:(NSNotification *)notification {
    DFURLNetworkReachabilityStatus status = [notification.userInfo[DFURLReachabilityNotificationStatusItem] integerValue];
    if (status != DFURLNetworkReachabilityStatusNotReachable &&
        _state == DFURLSessionTaskStateWaiting) {
        self.state = DFURLSessionTaskStateRunning;
    }
}

#pragma mark - <NSLocking>

- (void)lock {
    [_lock lock];
}

- (void)unlock {
    [_lock unlock];
}

@end
