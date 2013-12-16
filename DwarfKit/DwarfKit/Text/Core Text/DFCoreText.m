/*
 The MIT License (MIT)
 
 Copyright (c) 2013 Alexander Grebenyuk (github.com/kean).
 
 Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:
 
 The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.
 
 THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
 */

#import "DFCoreText.h"
#import <CoreText/CoreText.h>


@implementation DFCoreText

+ (CGSize)suggestAttributedStringSize:(NSAttributedString *)attributedString constraints:(CGSize)constraints numberOfLines:(NSUInteger)numberOfLines {
    if (!attributedString) {
        return CGSizeZero;
    }
    CTFramesetterRef framesetter = CTFramesetterCreateWithAttributedString((__bridge CFAttributedStringRef)(attributedString));
    if (!framesetter) {
        return CGSizeZero;
    }
    CGSize size = [self suggestFramesetterSize:framesetter constraints:constraints numberOfLines:numberOfLines];
    CFRelease(framesetter);
    return size;
}

+ (CGSize)suggestFramesetterSize:(CTFramesetterRef)framesetter constraints:(CGSize)constraints numberOfLines:(NSUInteger)numberOfLines {
    CFRange range = CFRangeMake(0, 0);
    
    if (numberOfLines > 0) {
        CGMutablePathRef path = CGPathCreateMutable();
        CGPathAddRect(path, NULL, CGRectMake(0, 0, constraints.width, constraints.height));
        CTFrameRef frame = CTFramesetterCreateFrame(framesetter, CFRangeMake(0, 0), path, NULL);
        CFArrayRef lines = CTFrameGetLines(frame);
        
        if (lines && CFArrayGetCount(lines) > 0) {
            NSInteger lastVisibleLineIndex = MIN(numberOfLines, CFArrayGetCount(lines)) - 1;
            CTLineRef lastVisibleLine = CFArrayGetValueAtIndex(lines, lastVisibleLineIndex);
            CFRange rangeToLayout = CTLineGetStringRange(lastVisibleLine);
            range = CFRangeMake(0, rangeToLayout.location + rangeToLayout.length);
        }
        
        CFRelease(frame);
        CFRelease(path);
    }
    
    CFRange fitCFRange = CFRangeMake(0, 0);
    CGSize size = CTFramesetterSuggestFrameSizeWithConstraints(framesetter, range, NULL, constraints, &fitCFRange);
    return CGSizeMake(ceilf(size.width), ceilf(size.height));
}

@end
