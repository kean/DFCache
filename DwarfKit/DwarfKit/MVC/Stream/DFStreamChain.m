//
//  DFPagerChain.m
//  DwarfKit
/*
 The MIT License (MIT)
 
 Copyright (c) 2013 Alexander Grebenyuk (github.com/kean).
 
 Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:
 
 The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.
 
 THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
 */

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
