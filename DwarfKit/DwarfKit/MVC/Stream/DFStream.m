//
//  DFPager.m
//  DwarfKit
//
//  Created by Alexander Grebenyuk on 10/1/13.
//  Copyright (c) 2013 com.github.kean. All rights reserved.
//

#import "DFStream.h"

@implementation DFStream {
    BOOL _isPolling;
    BOOL _isEnded;
}

- (BOOL)poll {
    if ([self isPolling] || [self isEnded]) {
        return NO;
    }
    _isPolling = YES;
    [_dataProvider poll:self];
    [_delegate streamDidStartPolling:self];
    return YES;
}

- (BOOL)isPolling {
    return _isPolling;
}

- (BOOL)isEnded {
    return _isEnded;
}

- (void)cancel {
    _isPolling = NO;
    [_dataProvider cancel:self];
    [_delegate streamDidCancel:self];
}

- (void)reset {
    _isEnded = NO;
    [self cancel];
}

- (void)processPolledData:(id)data isEnd:(BOOL)isEnd userInfo:(id)userInfo {
    _isPolling = NO;
    _isEnded = isEnd;
    [_delegate stream:self didRecieveData:data userInfo:userInfo];
    if (isEnd) {
        [_delegate streamDidEnd:self];
    }
}

- (void)processPollError:(NSError *)error isEnd:(BOOL)isEnd userInfo:(id)userInfo {
    _isPolling = NO;
    _isEnded = isEnd;
    [_delegate stream:self didFailWithError:error userInfo:userInfo];
    if (isEnd) {
        [_delegate streamDidEnd:self];
    }
}

@end
