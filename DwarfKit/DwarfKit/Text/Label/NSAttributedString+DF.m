/*
 The MIT License (MIT)
 
 Copyright (c) 2013 Alexander Grebenyuk (github.com/kean).
 
 Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:
 
 The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.
 
 THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
 */

#import "DFLabelDefines.h"
#import "DFTextAttachement.h"
#import "DFCoreText.h"
#import "NSAttributedString+DF.h"


@implementation NSAttributedString (DF)

- (CGSize)suggestedSizeWithConstraints:(CGSize)constraints numberOfLines:(NSUInteger)numberOfLines {
    return [DFCoreText suggestAttributedStringSize:self constraints:constraints numberOfLines:numberOfLines];
}

- (NSArray *)attachements {
    NSMutableArray *attachements = [NSMutableArray new];
    for (NSUInteger i = 0; i < self.length; i++) {
        DFTextAttachement *attachement = [self attribute:DFTextAttachementAttributeName atIndex:i effectiveRange:NULL];
        if (attachement) {
            [attachements addObject:attachement];
        }
    }
    return attachements;
}

- (BOOL)hasAttachements {
    if (self.length == 0) {
        return NO;
    }
    NSNumber *value = [self attribute:DFHasTextAttachementsAttributeName atIndex:0 effectiveRange:NULL];
    return !!value;
}

@end
