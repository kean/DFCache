/*
 The MIT License (MIT)
 
 Copyright (c) 2013 Alexander Grebenyuk (github.com/kean).
 
 Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:
 
 The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.
 
 THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
 */

#import "DFURLConnectionOperationDelegate.h"
#import "DFURLSessionRequest.h"
#import "DFURLSessionTaskConfiguration.h"
#import "DFURLSessionProtocol.h"
#import "DFURLSessionResponse.h"


typedef NS_ENUM(NSUInteger, DFURLSessionTaskState) {
    DFURLSessionTaskStateSuspended,
    DFURLSessionTaskStateRunning,
    DFURLSessionTaskStateWaiting,
    DFURLSessionTaskStateFailed,
    DFURLSessionTaskStateSucceed,
    DFURLSessionTaskStateCancelled
};


typedef void (^DFURLSessionSuccessBlock)(DFURLSessionResponse *response, DFURLSessionTask *task);
typedef void (^DFURLSessionFailureBlock)(NSError *error, DFURLSessionTask *task);
typedef void (^DFURLSessionProgressBlock)(DFURLProgress progress, DFURLSessionTask *task);


extern NSString *const DFURLSessionTaskDidFailAttemptNotification;


@interface DFURLSessionTask : NSObject <DFURLConnectionOperationDelegate, NSLocking>

@property (nonatomic, weak) id<DFURLSession> session;
@property (nonatomic, readonly) DFURLSessionTaskState state;
@property (nonatomic, readonly) id<DFURLSessionRequest> request;
@property (nonatomic, readonly) DFURLSessionResponse *response;
@property (nonatomic, readonly) DFURLProgress progress;
@property (nonatomic, readonly) NSError *error;
@property (nonatomic, readonly) DFURLSessionTaskConfiguration *configuration;
@property (nonatomic) id userInfo;

- (id)initWithSession:(id<DFURLSession>)session
              request:(id<DFURLSessionRequest>)request
        configuration:(DFURLSessionTaskConfiguration *)configuration;

- (void)run;
- (void)cancel;

#pragma mark - States

+ (BOOL)isStateFinal:(DFURLSessionTaskState)state;

#pragma mark - Handlers

- (void)addHandler:(id)handler
           success:(DFURLSessionSuccessBlock)success
           failure:(DFURLSessionFailureBlock)failure
          progress:(DFURLSessionProgressBlock)progress;
- (void)addHandler:(id)handler
           success:(DFURLSessionSuccessBlock)success
           failure:(DFURLSessionFailureBlock)failure;
- (void)removeHandler:(id)handler;

@end
