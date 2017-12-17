// The MIT License (MIT)
//
// Copyright (c) 2015 Alexander Grebenyuk (github.com/kean).

#import "DFCacheTimer.h"
#import <objc/runtime.h>

@implementation DFCacheTimer

static char _blockToken;

+ (NSTimer *)scheduledTimerWithTimeInterval:(NSTimeInterval)timeInterval block:(void (^)(void))block userInfo:(id)userInfo repeats:(BOOL)repeats {
    NSTimer *timer = [NSTimer scheduledTimerWithTimeInterval:timeInterval target:self selector:@selector(_timerDidFire:) userInfo:userInfo repeats:repeats];
    objc_setAssociatedObject(timer, &_blockToken, block, OBJC_ASSOCIATION_COPY);
    return timer;
}

+ (NSTimer *)timerWithTimeInterval:(NSTimeInterval)timeInterval block:(void (^)(void))block userInfo:(id)userInfo repeats:(BOOL)repeats {
    NSTimer *timer = [NSTimer timerWithTimeInterval:timeInterval target:self selector:@selector(_timerDidFire:) userInfo:userInfo repeats:repeats];
    objc_setAssociatedObject(timer, &_blockToken, block, OBJC_ASSOCIATION_COPY);
    return timer;
}

+ (void)_timerDidFire:(NSTimer *)timer {
    void (^block)(void) = objc_getAssociatedObject(timer, &_blockToken);
    if (block) {
        block();
    }
}

@end
