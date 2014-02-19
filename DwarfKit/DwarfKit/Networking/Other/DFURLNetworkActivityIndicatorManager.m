/*
 The MIT License (MIT)
 
 Copyright (c) 2013 Alexander Grebenyuk (github.com/kean).
 
 Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:
 
 The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.
 
 THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
 */

#import "DFURLNetworkActivityIndicatorManager.h"
#import "DFURLConnectionOperation.h"


@interface DFURLNetworkActivityIndicatorManager ()

@property (nonatomic, getter = isIndicatorVisible) BOOL indicationVisible;

@end

@implementation DFURLNetworkActivityIndicatorManager {
    NSInteger _connectionCount;
}

+ (instancetype)shared {
    static DFURLNetworkActivityIndicatorManager *shared = nil;
    static dispatch_once_t oncePredicate;
    dispatch_once(&oncePredicate, ^{
        shared = [self new];
    });
    return shared;
}

- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (id)init {
    if (self = [super init]) {
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(_connectionDidStart:) name:DFURLConnectionDidStartNotification object:nil];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(_connectionDidStop:) name:DFURLConnectionDidStopNotification object:nil];
    }
    return self;
}

- (void)_updateIndicatorVisibility {
    self.indicationVisible = !!_connectionCount;
}

- (void)setIndicationVisible:(BOOL)indicationVisible {
    if (_indicationVisible != indicationVisible) {
        _indicationVisible = indicationVisible;
        [[UIApplication sharedApplication] setNetworkActivityIndicatorVisible:indicationVisible];
    }
}

#pragma mark - DFURLConnectionOperation Notificafions

- (void)_connectionDidStart:(NSNotification *)notification {
    @synchronized(self) {
        _connectionCount++;
        [self _updateIndicatorVisibility];
    }
}

- (void)_connectionDidStop:(NSNotification *)notification {
    @synchronized(self) {
        _connectionCount--;
        [self _updateIndicatorVisibility];
        [[self class] cancelPreviousPerformRequestsWithTarget:self];
        [self performSelector:@selector(_updateIndicatorVisibility) withObject:nil afterDelay:0.15f inModes:@[NSRunLoopCommonModes]];
    }
}

@end
