/*
 The MIT License (MIT)
 
 Copyright (c) 2013 Alexander Grebenyuk (github.com/kean).
 
 Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:
 
 The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.
 
 THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
 */

#import "DFURLReachabilityManager.h"


NSString *const DFURLReachabilityDidChangeNotification = @"DFURLReachabilityDidChangeNotification";
NSString *const DFURLReachabilityStatusKey = @"DFURLReachabilityStatusKey";

#warning NOT TESTED
static DFURLReachabilityStatus DFURLReachabilityStatusForFlags(SCNetworkReachabilityFlags flags) {
    BOOL isReachable = ((flags & kSCNetworkReachabilityFlagsReachable) != 0);
    BOOL connectionRequired = ((flags & kSCNetworkReachabilityFlagsConnectionRequired) != 0);
    BOOL canConnectAutomatically = (((flags & kSCNetworkReachabilityFlagsConnectionOnDemand ) != 0) || ((flags & kSCNetworkReachabilityFlagsConnectionOnTraffic) != 0));
    BOOL canConnectWithoutUserInteraction = (canConnectAutomatically && (flags & kSCNetworkReachabilityFlagsInterventionRequired) == 0);
    BOOL isNetworkReachable = (isReachable && (!connectionRequired || canConnectWithoutUserInteraction));
    
    DFURLReachabilityStatus status;
    if (isNetworkReachable == NO) {
        status = DFURLReachabilityStatusNotReachable;
    }
#if	TARGET_OS_IPHONE
    else if ((flags & kSCNetworkReachabilityFlagsIsWWAN) != 0) {
        status = DFURLReachabilityStatusReachableViaWWAN;
    }
#endif
    else {
        status = DFURLReachabilityStatusReachableViaWiFi;
    }
    return status;
}

static void DFURLReachabilityCallback(SCNetworkReachabilityRef __unused target, SCNetworkReachabilityFlags flags, void *info) {
    DFURLReachabilityStatus status = DFURLReachabilityStatusForFlags(flags);
    dispatch_async(dispatch_get_main_queue(), ^{
        NSNotificationCenter *notificationCenter = [NSNotificationCenter defaultCenter];
        [notificationCenter postNotificationName:DFURLReachabilityDidChangeNotification object:nil userInfo:@{ DFURLReachabilityStatusKey: @(status) }];
    });
}


@implementation DFURLReachabilityManager {
    SCNetworkReachabilityRef _reachability;
    BOOL _isMonitoring;
}

- (void)dealloc {
    [self stopMonitoring];
    if (_reachability) {
        CFRelease(_reachability);
        _reachability = NULL;
    }
}

+ (instancetype)shared {
    static DFURLReachabilityManager *_shared;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        struct sockaddr_in address;
        bzero(&address, sizeof(address));
        address.sin_len = sizeof(address);
        address.sin_family = AF_INET;
        _shared = [[self alloc] initWithSocket:&address];
    });
    return _shared;
}

- (id)initWithReachability:(SCNetworkReachabilityRef)reachability {
    if (self = [super init]) {
        NSParameterAssert(reachability);
        _reachability = reachability;
    }
    return self;
}

- (id)initWithDomain:(NSString *)domain {
    SCNetworkReachabilityRef reachability = SCNetworkReachabilityCreateWithName(kCFAllocatorDefault, [domain UTF8String]);
    return [self initWithReachability:reachability];
}

- (id)initWithSocket:(const struct sockaddr_in *)socket {
    SCNetworkReachabilityRef reachability = SCNetworkReachabilityCreateWithAddress(kCFAllocatorDefault, (const struct sockaddr *)socket);
    return [self initWithReachability:reachability];
}

#pragma mark - Status

- (DFURLReachabilityStatus)status {
    DFURLReachabilityStatus status = DFURLReachabilityStatusNotReachable;
	SCNetworkReachabilityFlags flags;
	if (SCNetworkReachabilityGetFlags(_reachability, &flags)) {
        status = DFURLReachabilityStatusForFlags(flags);
	}
	return status;
}

- (BOOL)isReachable {
    return [self status] != DFURLReachabilityStatusNotReachable;
}

- (BOOL)isReachableViaWWAN {
    return [self status] == DFURLReachabilityStatusReachableViaWWAN;
}

- (BOOL)isReachableViaWiFi {
    return [self status] == DFURLReachabilityStatusReachableViaWiFi;
}

#pragma mark - Monitoring

- (void)startMonitoring {
    if (!_isMonitoring) {
        _isMonitoring = YES;
        SCNetworkReachabilitySetCallback(_reachability, DFURLReachabilityCallback, NULL);
        SCNetworkReachabilityScheduleWithRunLoop(_reachability, CFRunLoopGetMain(), kCFRunLoopCommonModes);
    }
}

- (void)stopMonitoring {
    if (!_isMonitoring) {
        _isMonitoring = NO;
        SCNetworkReachabilityUnscheduleFromRunLoop(_reachability, CFRunLoopGetMain(), kCFRunLoopCommonModes);
    }
}

@end
