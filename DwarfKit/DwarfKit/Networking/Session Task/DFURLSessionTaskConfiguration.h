/*
 The MIT License (MIT)
 
 Copyright (c) 2013 Alexander Grebenyuk (github.com/kean).
 
 Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:
 
 The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.
 
 THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
 */

#import "DFURLResponseDeserializing.h"
#import "DFURLDelay.h"


#pragma mark - DFURLSessionTaskConfiguration

@class DFURLRetryConfiguration;

@interface DFURLSessionTaskConfiguration : NSObject <NSCopying>

@property (nonatomic) id<DFURLResponseDeserializing> deserializer;
@property (nonatomic) BOOL cachingEnabled;
@property (nonatomic) BOOL cancelsWhenZeroHandlers;
@property (nonatomic) DFURLRetryConfiguration *retryConfiguration;

@end


#pragma mark - DFURLDelayConfiguration

typedef CGFloat (^DFURLDelayIncrementBlock)(CGFloat delay, CGFloat increaseRate, CGFloat maxDelay);

@interface DFURLDelayConfiguration : NSObject <NSCopying>

@property (nonatomic) CGFloat initialDelay;
@property (nonatomic) CGFloat maximumDelay;
@property (nonatomic) CGFloat delayIncreaseRate;
@property (nonatomic, copy) DFURLDelayIncrementBlock delayIncrement;

- (void)setDelayIncrement:(DFURLDelayIncrementBlock)delayIncrement;

@end


#pragma mark - DFURLRetryConfiguration

@class DFURLSessionTask, DFURLRetryConfiguration;

typedef BOOL (^DFURLShouldRetryBlock)(NSError *error, NSUInteger currentAttemptCount, DFURLRetryConfiguration *configuration, DFURLSessionTask *task);

@interface DFURLRetryConfiguration : NSObject <NSCopying>

@property (nonatomic) NSUInteger maximumAttempts;
@property (nonatomic) DFURLDelayConfiguration *delayConfiguration;
@property (nonatomic, copy) DFURLShouldRetryBlock shouldRetry;

+ (instancetype)defaultConfiguration;
+ (instancetype)inifiniteConfiguration;

- (void)setShouldRetry:(DFURLShouldRetryBlock)shouldRetry;

@end
