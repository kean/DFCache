/*
 The MIT License (MIT)
 
 Copyright (c) 2013 Alexander Grebenyuk (github.com/kean).
 
 Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:
 
 The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.
 
 THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
 */

#import "DFURLDelay.h"
#import "DFURLSessionTaskConfiguration.h"

@implementation DFURLDelay {
    CGFloat _delay;
    DFURLDelayConfiguration *_conf;
}

- (id)initWithConfiguration:(DFURLDelayConfiguration *)configuration {
    if (self = [super init]) {
        if (!configuration) {
            [NSException raise:NSInvalidArgumentException format:@"Attempting to initialize delay without configuration"];
        }
        _delay = configuration.initialDelay;
        _conf = configuration;
    }
    return self;
}

- (CGFloat)currentDelay {
    CGFloat delay = _delay;
    if (!_conf.delayIncrement) {
        [NSException raise:NSInternalInconsistencyException format:@"Attempting to calculate delay without increment block"];
    }
    _delay = _conf.delayIncrement(delay, _conf.delayIncreaseRate, _conf.maximumDelay);
    return delay;
}

@end
