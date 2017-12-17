// The MIT License (MIT)
//
// Copyright (c) 2015 Alexander Grebenyuk (github.com/kean).

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface DFCacheTimer : NSTimer

+ (NSTimer *)scheduledTimerWithTimeInterval:(NSTimeInterval)timeInterval block:(void (^)(void))block userInfo:(nullable id)userInfo repeats:(BOOL)repeats;
+ (NSTimer *)timerWithTimeInterval:(NSTimeInterval)timeInterval block:(void (^)(void))block userInfo:(nullable id)userInfo repeats:(BOOL)repeats;

@end

NS_ASSUME_NONNULL_END
