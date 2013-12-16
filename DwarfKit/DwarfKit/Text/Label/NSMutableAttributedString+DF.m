/*
 The MIT License (MIT)
 
 Copyright (c) 2013 Alexander Grebenyuk (github.com/kean).
 
 Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:
 
 The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.
 
 THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
 */

#import "DFLabelDefines.h"
#import "DFTextAttachement.h"
#import "NSMutableAttributedString+DF.h"
#import <CoreText/CTRunDelegate.h>
#import <CoreText/CTStringAttributes.h>


@implementation NSMutableAttributedString (DF)

- (void)addAttribute:(NSString *)attribute value:(id)value {
    NSAssert1(attribute, @"NSMutableString: attempted to insert value for nil attribute name [%@]", value);
    NSAssert1(value, @"NSMutableString: attempting to insert nil for attribute name %@", attribute);
    [self addAttribute:attribute value:value range:NSMakeRange(0, self.length)];
}

#pragma mark - Attachements

CGFloat DFTextAttachementDelegateGetAscentCallback(void *refCon);
CGFloat DFTextAttachementDelegateGetDescentCallback(void *refCon);
CGFloat DFTextAttachementDelegateGetWidthCallback(void *refCon);

CGFloat DFTextAttachementDelegateGetAscentCallback(void *refCon) {
    return [(__bridge DFTextAttachement *)refCon ascent];
}

CGFloat DFTextAttachementDelegateGetDescentCallback(void *refCon) {
    return [(__bridge DFTextAttachement *)refCon descent];
}

CGFloat DFTextAttachementDelegateGetWidthCallback(void *refCon) {
    DFTextAttachement *attachement = (__bridge DFTextAttachement *)refCon;
    return attachement.size.width + attachement.insets.left + attachement.insets.right;
}

- (void)insertAttachement:(DFTextAttachement *)attachement atIndex:(NSUInteger)index {
    if (!attachement) {
        return;
    }
    NSAttributedString *attachementString = [NSMutableAttributedString _attributedStringWithTextAttachement:attachement atIndex:index];
    [self _insertAttachementString:attachementString atIndex:index];
}

+ (NSMutableAttributedString *)_attributedStringWithTextAttachement:(DFTextAttachement *)attachement atIndex:(NSUInteger)index {
    if (!attachement) {
        return nil;
    }
    
    CTRunDelegateCallbacks callbacks;
    callbacks.version = kCTRunDelegateVersion1;
    callbacks.getAscent = DFTextAttachementDelegateGetAscentCallback;
    callbacks.getDescent = DFTextAttachementDelegateGetDescentCallback;
    callbacks.getWidth = DFTextAttachementDelegateGetWidthCallback;
    callbacks.dealloc = NULL;
    CTRunDelegateRef delegate = CTRunDelegateCreate(&callbacks, (__bridge void *)attachement);
    
    NSDictionary *attributes =
    @{ (__bridge id)kCTRunDelegateAttributeName : (__bridge id)delegate,
       DFTextAttachementAttributeName : attachement,
       DFTextAttachementIndexAttributeName : @(index) };
    NSMutableAttributedString *attachementString = [[NSMutableAttributedString alloc] initWithString:kDFTextAttachementCharacter attributes:attributes];
    
    CFRelease(delegate);
    
    return attachementString;
}

- (void)_insertAttachementString:(NSAttributedString *)string atIndex:(NSUInteger)index {
    if (!string) {
        return;
    }
    if (index > self.length) {
#ifdef DEBUG
        [NSException raise:@"DFLabel failure" format:@"Attempting to insert text attachement string %@ at index that is out of string bounds", string];
#endif
        return;
    }
    [self insertAttributedString:string atIndex:index];
    [self addAttribute:DFHasTextAttachementsAttributeName value:@YES range:NSMakeRange(0, 1)];
}

- (void)insertImage:(UIImage *)image baselineOffset:(CGFloat)baselineOffset atIndex:(NSUInteger)index {
    DFTextAttachementImage *attachement = [DFTextAttachementImage new];
    attachement.baselineOffset = baselineOffset;
    attachement.image = image;
    attachement.size = image.size;
    [self insertAttachement:attachement atIndex:index];
}

@end
