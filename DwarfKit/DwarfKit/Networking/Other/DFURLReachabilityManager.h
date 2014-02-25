/*
 The MIT License (MIT)
 
 Copyright (c) 2013 Alexander Grebenyuk (github.com/kean).
 
 Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:
 
 The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.
 
 THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
 */

#import <SystemConfiguration/SystemConfiguration.h>
#import <netinet/in.h>

typedef NS_ENUM(NSInteger, DFURLReachabilityStatus) {
    DFURLReachabilityStatusNotReachable     = 0,
    DFURLReachabilityStatusReachableViaWWAN = 1,
    DFURLReachabilityStatusReachableViaWiFi = 2,
};

extern NSString *const DFURLReachabilityDidChangeNotification;
extern NSString *const DFURLReachabilityStatusKey;

/*! DFURLReachabilityManager tracks the reachability of domains and addresses. For more info see Apple's Reachability Sample Code (https://developer.apple.com/library/ios/samplecode/reachability/)
 */
@interface DFURLReachabilityManager : NSObject

@property (nonatomic, readonly) DFURLReachabilityStatus status;

@property (nonatomic, readonly) BOOL isReachable;
@property (nonatomic, readonly) BOOL isReachableViaWWAN;
@property (nonatomic, readonly) BOOL isReachableViaWiFi;

+ (instancetype)shared;

- (id)initWithReachability:(SCNetworkReachabilityRef)reachability;
- (id)initWithDomain:(NSString *)domain;
- (id)initWithSocket:(const struct sockaddr_in *)socket;

- (void)startMonitoring;
- (void)stopMonitoring;

@end
