/*
 The MIT License (MIT)
 
 Copyright (c) 2013 Alexander Grebenyuk (github.com/kean).
 
 Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:
 
 The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.
 
 THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
 */

#import "DFTextAttachement.h"


@implementation DFTextAttachement

- (CALayer *)layerWithFrame:(CGRect)frame{
    return nil;
}

- (void)drawInContext:(CGContextRef)context rect:(CGRect)rect {
    // Do nothing
}

@end


@implementation DFTextAttachement (Helpers)

- (CGSize)boxSize {
    CGSize size = [self size];
    UIEdgeInsets insets = [self insets];
    return CGSizeMake(size.width + insets.left + insets.right,
                      size.height + insets.top + insets.bottom);
}

- (CGFloat)ascent {
    return self.boxSize.height - self.baselineOffset;
}

- (CGFloat)descent {
    return self.baselineOffset;
}

@end


@implementation DFTextAttachementImage {
    CALayer *_layer;
}

- (id)init {
    if (self = [super init]) {
        _opaque = YES;
    }
    return self;
}


- (CALayer *)layerWithFrame:(CGRect)frame {
    if (!_image) {
        return nil;
    }
    if (!_layer) {
        _layer = [CALayer new];
        _layer.contents = (id)_image.CGImage;
        _layer.opaque = _opaque;
        _layer.contentsScale = [UIScreen mainScreen].scale;
    }
    _layer.frame = frame;
    return _layer;
}

@end
