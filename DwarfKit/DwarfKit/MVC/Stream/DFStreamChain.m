//
//  DFPagerChain.m
//  DwarfKit
//
//  Created by Alexander Grebenyuk on 10/1/13.
//  Copyright (c) 2013 com.github.kean. All rights reserved.
//

#import "DFStreamChain.h"

@implementation DFStreamChain {
    NSMutableArray *_streams;
}

- (id)init {
    if (self = [super init]) {
        _streams = [NSMutableArray new];
    }
    return self;
}

- (id)initWithStream:(id<DFStream>)stream {
    if (self = [super init]) {
        [_streams addObject:stream];
    }
    return self;
}

- (void)addStream:(id<DFStream>)stream {
    [_streams addObject:stream];
}

- (BOOL)isEnded {
    for (id<DFStream> stream in _streams) {
        if (![stream isEnded]) {
            return NO;
        }
    }
    return YES;
}

- (BOOL)isPolling {
    for (id<DFStream> stream in _streams) {
        if ([stream isPolling]) {
            return YES;
        }
    }
    return NO;
}

- (BOOL)poll {
    for (id<DFStream> stream in _streams) {
        if ([stream poll]) {
            return YES;
        }
    }
    return NO;
}

- (void)reset {
    [_streams makeObjectsPerformSelector:@selector(reset)];
}

- (void)cancel {
    [_streams makeObjectsPerformSelector:@selector(cancel)];
}

@end
