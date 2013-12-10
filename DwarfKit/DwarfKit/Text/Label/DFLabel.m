/*
 The MIT License (MIT)
 
 Copyright (c) 2013 Alexander Grebenyuk (github.com/kean).
 
 Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:
 
 The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.
 
 THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
 */

#import "DFCoreText.h"
#import "DFLabel.h"
#import "DFLabelDefines.h"
#import "NSMutableAttributedString+DF.h"
#import <CoreText/CoreText.h>
#import <QuartzCore/QuartzCore.h>


static const CGFloat _kLinkVerticalMargin = 5.0f;
static NSString *const _kLinkAttributedName = @"DFLabel:Link";

static NSString *const _kEllipsesCharacter = @"\u2026";
static NSString *const _kAttachementCharacter = @"\uFFFC";

// The amount of space around a link that will still register as tapping "within" the link.
static const CGFloat _kTouchGutter = 22;


@interface DFLabel() <UIActionSheetDelegate, UIGestureRecognizerDelegate>

@property (nonatomic, assign) CTFrameRef frameRef;
@property (nonatomic, assign) CTFramesetterRef framesetterRef;

@end


@implementation DFLabel {
// UILabel
    NSString *_text;
    NSMutableAttributedString *_mutableAttributedString;
    UIColor *_textColor;
    UIColor *_highlightedTextColor;
    UIFont *_font;
    NSTextAlignment _textAlignment;
    NSLineBreakMode _lineBreakMode;
    
// DFLabel
    NSMutableParagraphStyle *_paragraphStyle;
    CTFramesetterRef _framesetterRef;
    CTFrameRef _frameRef;
    NSMutableDictionary *_attachementsLayers;
    NSMutableArray *_detectedLinkLocations;
    NSMutableArray *_explicitLinkLocations;
    NSTextCheckingResult *_touchedTextCheckingResult;
}

- (void)dealloc {
    self.frameRef = nil;
    self.framesetterRef = nil;
}

- (id)initWithFrame:(CGRect)frame {
    if ((self = [super initWithFrame:frame])) {
        [self _commonInit];
    }
    return self;
}

- (id)initWithCoder:(NSCoder *)aDecoder {
    if (self = [super initWithCoder:aDecoder]){
        [self _commonInit];
        if (_text.length) {
            self.attributedText = [[NSMutableAttributedString alloc] initWithString:_text attributes:self.textAttributes];
        }
    }
    return self;
}

- (void)_commonInit {
    self.backgroundColor = [UIColor clearColor];
    
    _font = [UIFont systemFontOfSize:14.f];
    _textColor = [UIColor blackColor];
    
    _paragraphStyle = [NSMutableParagraphStyle new];
    _explicitLinkLocations = [NSMutableArray new];
    _detectedLinkLocations = [NSMutableArray new];
    _attachementsLayers = [NSMutableDictionary new];
    
    _dataHighlightColor = [UIColor lightGrayColor];
    _dataTextAttributes = @{ NSForegroundColorAttributeName : [UIColor blueColor],
                             NSUnderlineStyleAttributeName : @(NSUnderlinePatternSolid) };
    
    _ellipsesString = _kEllipsesCharacter;
    
    _tapGestureRecognizer = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(_handleTapGestureRecognizer:)];
    [self addGestureRecognizer:_tapGestureRecognizer];
}

- (CGSize)sizeThatFits:(CGSize)size {
    return [DFCoreText suggestFramesetterSize:self.framesetterRef constraints:size numberOfLines:self.numberOfLines];
}

- (NSDictionary *)textAttributes {
    return @{ NSFontAttributeName : self.font,
              NSForegroundColorAttributeName : self.textColor,
              NSParagraphStyleAttributeName : _paragraphStyle };
}

#warning Not all UILabel methods are implemented.
#pragma mark - UILabel Overrides

- (NSString *)text {
    return _text;
}

- (void)setText:(NSString *)text {
    if (_text != text) {
        _text = text;
        self.attributedText = text.length ? [[NSMutableAttributedString alloc] initWithString:_text attributes:self.textAttributes] : nil;
    }
}

- (NSAttributedString *)attributedText {
    return [_mutableAttributedString copy];
}

- (void)setAttributedText:(NSAttributedString *)attributedText {
    if (_mutableAttributedString != attributedText) {
        _mutableAttributedString = [attributedText mutableCopy];
        
        // Update links information
        [_detectedLinkLocations removeAllObjects];
        [_explicitLinkLocations removeAllObjects];
        [self _detectLinks];
        
        // Clear attachements
        self.layer.sublayers = nil;
        [_attachementsLayers removeAllObjects];
        
        [self _attributedStringDidChange];
    }
}

- (UIColor *)textColor {
    return _textColor;
}

- (void)setTextColor:(UIColor *)textColor {
    if (_textColor != textColor) {
        _textColor = textColor;
        if (_mutableAttributedString) {
            [_mutableAttributedString addAttribute:NSFontAttributeName value:textColor];
            [self _attributedStringDidChange];
        }
    }
}

- (UIFont *)font {
    return _font;
}

- (void)setFont:(UIFont *)font {
    if (_font != font) {
        _font = font;
        if (_mutableAttributedString) {
            [_mutableAttributedString addAttribute:NSFontAttributeName value:font];
            [self _attributedStringDidChange];
        }
    }
}

- (NSTextAlignment)textAlignment {
    return _textAlignment;
}

- (void)setTextAlignment:(NSTextAlignment)textAlignment {
    if (_textAlignment != textAlignment) {
        _textAlignment = textAlignment;
        _paragraphStyle.alignment = textAlignment;
        if (_mutableAttributedString) {
            [_mutableAttributedString addAttribute:NSParagraphStyleAttributeName value:_paragraphStyle];
            [self _attributedStringDidChange];
        }
    }
}

- (NSLineBreakMode)lineBreakMode {
    return _lineBreakMode;
}

- (void)setLineBreakMode:(NSLineBreakMode)lineBreakMode {
    if (_lineBreakMode != lineBreakMode) {
        _lineBreakMode = lineBreakMode;
        // Tail truncation is handled manually.
        if (self.lineBreakMode == NSLineBreakByTruncatingTail) {
            _paragraphStyle.lineBreakMode = NSLineBreakByWordWrapping;
        } else {
            _paragraphStyle.lineBreakMode = lineBreakMode;
        }
        if (_mutableAttributedString) {
            [_mutableAttributedString addAttribute:NSParagraphStyleAttributeName value:_paragraphStyle];
            [self _attributedStringDidChange];
        }
    }
}

- (UIColor *)highlightedTextColor {
    return _highlightedTextColor;
}

- (void)setHighlightedTextColor:(UIColor *)highlightedTextColor {
    if (_highlightedTextColor != highlightedTextColor) {
        _highlightedTextColor = highlightedTextColor;
    }
}

- (void)setHighlighted:(BOOL)highlighted {
    BOOL didChange = self.highlighted != highlighted;
    [super setHighlighted:highlighted];
    if (!didChange) {
        return;
    }
    if (!_highlightedTextColor) {
        return;
    }
    [_mutableAttributedString addAttribute:NSForegroundColorAttributeName value:_highlightedTextColor];
#warning Might not be necessary.
    [self _attributedStringDidChange];
}

#pragma mark - Drawing

- (void)_attributedStringDidChange {
    self.framesetterRef = nil;
    [self _setNeedsRedrawLabel];
}

- (void)_setNeedsRedrawLabel {
    self.frameRef = nil;
    [self setNeedsDisplay];
}

- (void)setFrameRef:(CTFrameRef)frameRef {
    if (_frameRef != frameRef) {
        if (_frameRef) {
            CFRelease(_frameRef);
        }
        if (frameRef) {
            CFRetain(frameRef);
        }
        _frameRef = frameRef;
    }
}

- (CTFramesetterRef)framesetterRef {
    if (!_framesetterRef) {
        _framesetterRef = CTFramesetterCreateWithAttributedString((__bridge CFAttributedStringRef)(_mutableAttributedString));
    }
    return _framesetterRef;
}

- (void)setFramesetterRef:(CTFramesetterRef)framesetter {
    if (_framesetterRef != framesetter) {
        if (_framesetterRef) {
            CFRelease(_framesetterRef);
        }
        if (framesetter) {
            CFRetain(framesetter);
        }
        _framesetterRef = framesetter;
    }
}

#warning Verical text alighment is different from UILabel.
- (void)drawTextInRect:(CGRect)rect {
    if (!_mutableAttributedString) {
        return;
    }
    if (_detectedLinkLocations.count > 0 || _explicitLinkLocations.count > 0) {
        self.userInteractionEnabled = YES;
    }
    CGContextRef ctx = UIGraphicsGetCurrentContext();
    CGContextSaveGState(ctx);
    
    CGAffineTransform transform = [self _transformForCoreText];
    CGContextConcatCTM(ctx, transform);
    CGContextSetTextMatrix(ctx, CGAffineTransformIdentity);
    
    if (!_frameRef) {
        CGMutablePathRef path = CGPathCreateMutable();
        CGPathAddRect(path, NULL, rect);
        CTFrameRef frameRef = CTFramesetterCreateFrame([self framesetterRef], CFRangeMake(0, 0), path, NULL);
        self.frameRef = frameRef;
        if (frameRef) {
            CFRelease(frameRef);
        }
        CFRelease(path);
    }
    
    [self _drawTextAttachements];
    [self _drawDataHighlightWithRect:rect];
    
    if (self.shadowColor) {
        CGContextSetShadowWithColor(ctx, self.shadowOffset, _shadowBlur, self.shadowColor.CGColor);
    }
    
    [self _drawAttributedString:_mutableAttributedString rect:rect];
    
    CGContextRestoreGState(ctx);
}

- (void)_drawTextAttachements {
    if (!_mutableAttributedString.hasAttachements) {
        return;
    }
    
    CGContextRef ctx = UIGraphicsGetCurrentContext();
    
    CFArrayRef lines = CTFrameGetLines(_frameRef);
    CFIndex lineCount = CFArrayGetCount(lines);
    CGPoint lineOrigins[lineCount];
    CTFrameGetLineOrigins(_frameRef, CFRangeMake(0, 0), lineOrigins);
    NSInteger numberOfLines = [self _numberOfLines];
    
    for (CFIndex i = 0; i < numberOfLines; i++) {
        CTLineRef line = CFArrayGetValueAtIndex(lines, i);
        CFArrayRef runs = CTLineGetGlyphRuns(line);
        CFIndex runCount = CFArrayGetCount(runs);
        CGPoint lineOrigin = lineOrigins[i];
        CGFloat lineAscent;
        CGFloat lineDescent;
        CTLineGetTypographicBounds(line, &lineAscent, &lineDescent, NULL);
        CGFloat lineBottomY = lineOrigin.y - lineDescent;
        
        // Iterate through each of the "runs" (i.e. a chunk of text) and find the runs that
        // intersect with the range.
        for (CFIndex k = 0; k < runCount; k++) {
            CTRunRef run = CFArrayGetValueAtIndex(runs, k);
            NSDictionary *attributes = (__bridge NSDictionary *)CTRunGetAttributes(run);
            DFTextAttachement *attachement = attributes[DFTextAttachementAttributeName];
            if (!attachement) {
                continue;
            }
            
            CGFloat ascent = 0.0f;
            CGFloat descent = 0.0f;
            CGFloat width = (CGFloat)CTRunGetTypographicBounds(run, CFRangeMake(0, 0), &ascent, &descent, NULL);
            
            CGFloat xOffset = CTLineGetOffsetForStringIndex(line, CTRunGetStringRange(run).location, nil);
            
            CGRect rect = CGRectMake(lineOrigin.x + xOffset, lineBottomY, width, attachement.boxSize.height);
            
            UIEdgeInsets flippedInsets = attachement.insets;
            CGFloat top = flippedInsets.top;
            flippedInsets.top = flippedInsets.bottom;
            flippedInsets.bottom = top;
            
            CGRect attachementRect = UIEdgeInsetsInsetRect(rect, flippedInsets);
            attachementRect = CGRectIntegral(attachementRect);
            NSNumber *attachementIndex = attributes[DFTextAttachementIndexAttributeName];
            
            CGRect flippedAttachementRect = CGRectApplyAffineTransform(rect, [self _transformForCoreText]);
            flippedAttachementRect.origin.x = floorf(flippedAttachementRect.origin.x);
            flippedAttachementRect.origin.y = floorf(flippedAttachementRect.origin.y);
            
            CALayer *layer = _attachementsLayers[attachementIndex];
            if (layer) {
                layer.frame = flippedAttachementRect;
                continue;
            }
            layer = [attachement layerWithFrame:flippedAttachementRect];
            if (layer) {
                [self.layer addSublayer:layer];
                _attachementsLayers[attachementIndex] = layer;
            } else {
                [attachement drawInContext:ctx rect:attachementRect];
            }
        }
    }
}

- (void)_drawDataHighlightWithRect:(CGRect)rect {
    if (!_touchedTextCheckingResult || !_dataHighlightColor) {
        return;
    }
    [_dataHighlightColor setFill];
    
    CFArrayRef lines = CTFrameGetLines(_frameRef);
    CFIndex count = CFArrayGetCount(lines);
    CGPoint lineOrigins[count];
    CTFrameGetLineOrigins(_frameRef, CFRangeMake(0, 0), lineOrigins);
    NSInteger numberOfLines = [self _numberOfLines];
    
    CGContextRef ctx = UIGraphicsGetCurrentContext();
    
    for (CFIndex i = 0; i < numberOfLines; i++) {
        CTLineRef line = CFArrayGetValueAtIndex(lines, i);
        
        CFRange stringRange = CTLineGetStringRange(line);
        NSRange lineRange = NSMakeRange(stringRange.location, stringRange.length);
        NSRange intersectedRange = NSIntersectionRange(lineRange, _touchedTextCheckingResult.range);
        if (intersectedRange.length == 0) {
            continue;
        }
        
        CGRect highlightRect = [self _rectForRange:_touchedTextCheckingResult.range inLine:line lineOrigin:lineOrigins[i]];
        highlightRect = CGRectOffset(highlightRect, 0, -rect.origin.y);
        
        if (!CGRectIsEmpty(highlightRect)) {
            CGFloat pi = (CGFloat)M_PI;
            
            CGFloat radius = 1.0f;
            CGContextMoveToPoint(ctx, highlightRect.origin.x, highlightRect.origin.y + radius);
            CGContextAddLineToPoint(ctx, highlightRect.origin.x, highlightRect.origin.y + highlightRect.size.height - radius);
            CGContextAddArc(ctx, highlightRect.origin.x + radius, highlightRect.origin.y + highlightRect.size.height - radius,
                            radius, pi, pi / 2.0f, 1.0f);
            CGContextAddLineToPoint(ctx, highlightRect.origin.x + highlightRect.size.width - radius,
                                    highlightRect.origin.y + highlightRect.size.height);
            CGContextAddArc(ctx, highlightRect.origin.x + highlightRect.size.width - radius,
                            highlightRect.origin.y + highlightRect.size.height - radius, radius, pi / 2, 0.0f, 1.0f);
            CGContextAddLineToPoint(ctx, highlightRect.origin.x + highlightRect.size.width, highlightRect.origin.y + radius);
            CGContextAddArc(ctx, highlightRect.origin.x + highlightRect.size.width - radius, highlightRect.origin.y + radius,
                            radius, 0.0f, -pi / 2.0f, 1.0f);
            CGContextAddLineToPoint(ctx, highlightRect.origin.x + radius, highlightRect.origin.y);
            CGContextAddArc(ctx, highlightRect.origin.x + radius, highlightRect.origin.y + radius, radius,
                            -pi / 2, pi, 1);
            CGContextFillPath(ctx);
        }
    }
}

- (void)_drawAttributedString:(NSAttributedString *)attributedString rect:(CGRect)rect {
    CGContextRef ctx = UIGraphicsGetCurrentContext();
#warning Might be broken for other line break modes.
    if (_lineBreakMode != NSLineBreakByTruncatingTail) {
        CTFrameDraw(_frameRef, ctx);
        return;
    }
    
    // Draw lines one by one and truncate last line if necessary.
    CFArrayRef lines = CTFrameGetLines(_frameRef);
    NSInteger numberOfLines = [self _numberOfLines];
    
    CGPoint lineOrigins[numberOfLines];
    CTFrameGetLineOrigins(_frameRef, CFRangeMake(0, numberOfLines), lineOrigins);
    
    for (CFIndex lineIndex = 0; lineIndex < numberOfLines; lineIndex++) {
        CGPoint lineOrigin = lineOrigins[lineIndex];
        CGContextSetTextPosition(ctx, lineOrigin.x, lineOrigin.y);
        CTLineRef line = CFArrayGetValueAtIndex(lines, lineIndex);
        if (lineIndex != numberOfLines - 1) {
            CTLineDraw(line, ctx);
            continue;
        }
        
        CFRange lastLineRange = CTLineGetStringRange(line);
        BOOL truncationRequired = (lastLineRange.location + lastLineRange.length < attributedString.length);
        if (!truncationRequired) {
            CTLineDraw(line, ctx);
            continue;
        }
        
        CTLineTruncationType truncationType = kCTLineTruncationEnd;
        NSUInteger truncationAttributePosition = lastLineRange.location + lastLineRange.length - 1;
        
        NSDictionary *tokenAttributes = [attributedString attributesAtIndex:truncationAttributePosition effectiveRange:NULL];
        NSAttributedString *tokenString = [[NSAttributedString alloc] initWithString:_ellipsesString attributes:tokenAttributes];
        CTLineRef truncationToken = CTLineCreateWithAttributedString((__bridge CFAttributedStringRef)tokenString);
        
        NSMutableAttributedString *truncationString = [[attributedString attributedSubstringFromRange:NSMakeRange(lastLineRange.location, lastLineRange.length)] mutableCopy];
        if (lastLineRange.length > 0) {
            // Remove any whitespace at the end of the line.
            unichar lastCharacter = [[truncationString string] characterAtIndex:lastLineRange.length - 1];
            if ([[NSCharacterSet whitespaceAndNewlineCharacterSet] characterIsMember:lastCharacter]) {
                [truncationString deleteCharactersInRange:NSMakeRange(lastLineRange.length - 1, 1)];
            }
        }
        
        [truncationString appendAttributedString:tokenString];
        
        CTLineRef truncationLine = CTLineCreateWithAttributedString((__bridge CFAttributedStringRef)truncationString);
        CTLineRef truncatedLine = CTLineCreateTruncatedLine(truncationLine, rect.size.width, truncationType, truncationToken);
        if (!truncatedLine) {
            // If the line is not as wide as the truncationToken, truncatedLine is NULL
            truncatedLine = CFRetain(truncationToken);
        }
        CFRelease(truncationLine);
        CFRelease(truncationToken);
        
        CTLineDraw(truncatedLine, ctx);
        CFRelease(truncatedLine);
    }
}

- (NSInteger)_numberOfLines {
    CFArrayRef lines = CTFrameGetLines(_frameRef);
    return self.numberOfLines > 0 ? MIN(self.numberOfLines, CFArrayGetCount(lines)) : CFArrayGetCount(lines);
}

#pragma mark - Data Detection

- (void)addLink:(NSURL *)link range:(NSRange)range {
    if (!link) {
        return;
    }
    NSTextCheckingResult *result = [NSTextCheckingResult linkCheckingResultWithRange:range URL:link];
    [_explicitLinkLocations addObject:result];
    [self _applyLinkStyleWithResults:_explicitLinkLocations];
    [self _setNeedsRedrawLabel];
}

- (void)_detectLinks {
    if (!_mutableAttributedString || !_dataDetector) {
        return;
    }
    NSString *stringInitial = _mutableAttributedString.string;
    NSString *string = [_mutableAttributedString.string copy];
    dispatch_queue_t queue = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0);
    dispatch_async(queue, ^{
        NSArray *matches = [_dataDetector matchesInString:string options:kNilOptions range:NSMakeRange(0, string.length)];
        dispatch_async(dispatch_get_main_queue(), ^{
            if (_mutableAttributedString.string != stringInitial) {
                return;
            }
            [_detectedLinkLocations addObjectsFromArray:matches];
            [self _applyLinkStyleWithResults:_detectedLinkLocations];
        });
    });
}

- (void)_applyLinkStyleWithResults:(NSArray *)results {
    if (!results.count) {
        return;
    }
    for (NSTextCheckingResult *result in results) {
        // We add a no-op attribute in order to force a run to exist for each link. Otherwise the runCount will be one in this line, causing the entire line to be highlighted rather than just the link when when no special attributes are set.
        [_mutableAttributedString addAttribute:_kLinkAttributedName
                                         value:[NSNumber numberWithBool:YES]
                                         range:result.range];
        if (_dataTextAttributes.count > 0) {
            [_mutableAttributedString addAttributes:_dataTextAttributes range:result.range];
        }
    }
    [self _attributedStringDidChange];
}

#pragma mark - Data Detection (Touch Events Handling)

- (void)_handleTapGestureRecognizer:(UITapGestureRecognizer *)recognizer {
    CGPoint tapLocation = [recognizer locationInView:self];
    
    _touchedTextCheckingResult = [self linkAtPoint:tapLocation];
    if (!_touchedTextCheckingResult) {
        return;
    }
    [self _setNeedsRedrawLabel];
    
    if ([_delegate respondsToSelector:@selector(label:shouldInteractWithTextCheckingResult:)]) {
        if (![_delegate label:self shouldInteractWithTextCheckingResult:_touchedTextCheckingResult]) {
            return;
        }
    }
    
    UIActionSheet *actionSheet = [self actionSheetForResult:_touchedTextCheckingResult];
    if ([[UIDevice currentDevice] userInterfaceIdiom] != UIUserInterfaceIdiomPad) {
        [actionSheet showFromRect:CGRectMake(tapLocation.x - 22, tapLocation.y - 22, 44, 44) inView:self animated:YES];
    } else {
        [actionSheet showInView:self];
    }
}

#warning Broken
- (NSTextCheckingResult *)linkAtPoint:(CGPoint)point {
    if (!CGRectContainsPoint(CGRectInset(self.bounds, 0, -_kLinkVerticalMargin), point)) {
        return nil;
    }
    
    CFArrayRef lines = CTFrameGetLines(_frameRef);
    if (!lines) return nil;
    CFIndex count = CFArrayGetCount(lines);
    
    NSTextCheckingResult *foundLink = nil;
    
    CGPoint origins[count];
    CTFrameGetLineOrigins(_frameRef, CFRangeMake(0,0), origins);
    
    CGAffineTransform transform = [self _transformForCoreText];
    
    for (int i = 0; i < count; i++) {
        CGPoint linePoint = origins[i];
        
        CTLineRef line = CFArrayGetValueAtIndex(lines, i);
        CGRect flippedRect = [self getLineBounds:line point:linePoint];
        CGRect rect = CGRectApplyAffineTransform(flippedRect, transform);
        
        rect = CGRectInset(rect, 0, -_kLinkVerticalMargin);
        
        if (CGRectContainsPoint(rect, point)) {
            CGPoint relativePoint = CGPointMake(point.x-CGRectGetMinX(rect),
                                                point.y-CGRectGetMinY(rect));
            CFIndex idx = CTLineGetStringIndexForPosition(line, relativePoint);
            
            foundLink = [self linkAtIndex:idx];;
            if (foundLink) {
                NSTextCheckingResult *result = [NSTextCheckingResult linkCheckingResultWithRange:NSMakeRange(foundLink.range.location, foundLink.range.length) URL:foundLink.URL];
                
                return result;
            }
        }
    }
    return nil;
}

- (CGRect)getLineBounds:(CTLineRef)line point:(CGPoint) point {
    CGFloat ascent = 0.0f;
    CGFloat descent = 0.0f;
    CGFloat leading = 0.0f;
    CGFloat width = (CGFloat)CTLineGetTypographicBounds(line, &ascent, &descent, &leading);
    CGFloat height = ascent + descent;
    return CGRectMake(point.x, point.y - descent, width, height);
}

- (NSTextCheckingResult *)linkAtIndex:(CFIndex)i {
    NSTextCheckingResult *foundResult = nil;
    for (NSTextCheckingResult *result in _detectedLinkLocations) {
        if (NSLocationInRange(i, result.range)) {
            foundResult = result;
            break;
        }
    }
    if (!foundResult) {
        for (NSTextCheckingResult *result in _explicitLinkLocations) {
            if (NSLocationInRange(i, result.range)) {
                foundResult = result;
                break;
            }
        }
    }
    return foundResult;
}

- (CGAffineTransform)_transformForCoreText {
    // CoreText context coordinates are the opposite to UIKit so we flip the bounds
    return CGAffineTransformScale(CGAffineTransformMakeTranslation(0, self.bounds.size.height), 1.f, -1.f);
}

- (CGRect)_rectForRange:(NSRange)range inLine:(CTLineRef)line lineOrigin:(CGPoint)lineOrigin {
    CGRect rectForRange = CGRectZero;
    CFArrayRef runs = CTLineGetGlyphRuns(line);
    CFIndex runCount = CFArrayGetCount(runs);
    
    // Iterate through each of the "runs" (i.e. a chunk of text) and find the runs that
    // intersect with the range.
    for (CFIndex k = 0; k < runCount; k++) {
        CTRunRef run = CFArrayGetValueAtIndex(runs, k);
        
        CFRange stringRunRange = CTRunGetStringRange(run);
        NSRange lineRunRange = NSMakeRange(stringRunRange.location, stringRunRange.length);
        NSRange intersectedRunRange = NSIntersectionRange(lineRunRange, range);
        
        if (intersectedRunRange.length == 0) {
            // This run doesn't intersect the range, so skip it.
            continue;
        }
        
        CGFloat ascent = 0.0f;
        CGFloat descent = 0.0f;
        CGFloat leading = 0.0f;
        
        // Use of 'leading' doesn't properly highlight Japanese-character link.
        CGFloat width = (CGFloat)CTRunGetTypographicBounds(run,
                                                           CFRangeMake(0, 0),
                                                           &ascent,
                                                           &descent,
                                                           NULL); //&leading);
        CGFloat height = ascent + descent;
        
        CGFloat xOffset = CTLineGetOffsetForStringIndex(line, CTRunGetStringRange(run).location, nil);
        
        CGRect linkRect = CGRectMake(lineOrigin.x + xOffset - leading, lineOrigin.y - descent, width + leading, height);
        
        linkRect.origin.y = roundf(linkRect.origin.y);
        linkRect.origin.x = roundf(linkRect.origin.x);
        linkRect.size.width = roundf(linkRect.size.width);
        linkRect.size.height = roundf(linkRect.size.height);
        
        if (CGRectIsEmpty(rectForRange)) {
            rectForRange = linkRect;
            
        } else {
            rectForRange = CGRectUnion(rectForRange, linkRect);
        }
    }
    
    return rectForRange;
}

- (BOOL)isPoint:(CGPoint)point nearLink:(NSTextCheckingResult *)link {
    CFArrayRef lines = CTFrameGetLines(_frameRef);
    if (nil == lines) {
        return NO;
    }
    CFIndex count = CFArrayGetCount(lines);
    CGPoint lineOrigins[count];
    CTFrameGetLineOrigins(_frameRef, CFRangeMake(0, 0), lineOrigins);
    
    CGAffineTransform transform = [self _transformForCoreText];
    
    NSRange linkRange = link.range;
    
    BOOL isNearLink = NO;
    for (int i = 0; i < count; i++) {
        CTLineRef line = CFArrayGetValueAtIndex(lines, i);
        
        CGRect linkRect = [self _rectForRange:linkRange inLine:line lineOrigin:lineOrigins[i]];
        
        if (!CGRectIsEmpty(linkRect)) {
            linkRect = CGRectApplyAffineTransform(linkRect, transform);
            linkRect = CGRectInset(linkRect, -_kTouchGutter, -_kTouchGutter);
            if (CGRectContainsPoint(linkRect, point)) {
                isNearLink = YES;
                break;
            }
        }
    }
    
    return isNearLink;
}

- (NSArray *)_rectsForLink:(NSTextCheckingResult *)link {
    CFArrayRef lines = CTFrameGetLines(_frameRef);
    if (nil == lines) {
        return nil;
    }
    CFIndex count = CFArrayGetCount(lines);
    CGPoint lineOrigins[count];
    CTFrameGetLineOrigins(_frameRef, CFRangeMake(0, 0), lineOrigins);
    
    CGAffineTransform transform = [self _transformForCoreText];
    
    NSRange linkRange = link.range;
    
    NSMutableArray *rects = [NSMutableArray array];
    for (int i = 0; i < count; i++) {
        CTLineRef line = CFArrayGetValueAtIndex(lines, i);
        
        CGRect linkRect = [self _rectForRange:linkRange inLine:line lineOrigin:lineOrigins[i]];
        
        if (!CGRectIsEmpty(linkRect)) {
            linkRect = CGRectApplyAffineTransform(linkRect, transform);
            [rects addObject:[NSValue valueWithCGRect:linkRect]];
        }
    }
    return [rects copy];
}

#pragma mark - UIActionSheet

- (UIActionSheet *)actionSheetForResult:(NSTextCheckingResult *)result {
    UIActionSheet *actionSheet =
    [[UIActionSheet alloc] initWithTitle:nil
                                delegate:self
                       cancelButtonTitle:nil
                  destructiveButtonTitle:nil
                       otherButtonTitles:nil];
    
    NSString *title = nil;
    if (NSTextCheckingTypeLink == result.resultType) {
        if ([result.URL.scheme isEqualToString:@"mailto"]) {
            title = result.URL.resourceSpecifier;
            [actionSheet addButtonWithTitle:NSLocalizedString(@"Open in Mail", @"")];
            [actionSheet addButtonWithTitle:NSLocalizedString(@"Copy Email Address", @"")];
            
        } else {
            title = result.URL.absoluteString;
            [actionSheet addButtonWithTitle:NSLocalizedString(@"Open in Safari", @"")];
            [actionSheet addButtonWithTitle:NSLocalizedString(@"Copy URL", @"")];
        }
        
    } else if (NSTextCheckingTypePhoneNumber == result.resultType) {
        title = result.phoneNumber;
        [actionSheet addButtonWithTitle:NSLocalizedString(@"Call", @"")];
        [actionSheet addButtonWithTitle:NSLocalizedString(@"Copy Phone Number", @"")];
        
    } else if (NSTextCheckingTypeAddress == result.resultType) {
        title = [_mutableAttributedString.string substringWithRange:_touchedTextCheckingResult.range];
        [actionSheet addButtonWithTitle:NSLocalizedString(@"Open in Maps", @"")];
        [actionSheet addButtonWithTitle:NSLocalizedString(@"Copy Address", @"")];
        
    } else {
        // This type has not been implemented yet.
        NSAssert(NO, nil);
        [actionSheet addButtonWithTitle:NSLocalizedString(@"Copy", @"")];
    }
    actionSheet.title = title;
    
    if ([[UIDevice currentDevice] userInterfaceIdiom] != UIUserInterfaceIdiomPad) {
        [actionSheet setCancelButtonIndex:[actionSheet addButtonWithTitle:NSLocalizedString(@"Cancel", @"")]];
    }
    
    return actionSheet;
}

- (void)actionSheet:(UIActionSheet*)actionSheet clickedButtonAtIndex:(NSInteger)buttonIndex {
    if (NSTextCheckingTypeLink == _touchedTextCheckingResult.resultType) {
        if (buttonIndex == 0) {
            [[UIApplication sharedApplication] openURL:_touchedTextCheckingResult.URL];
            
        } else if (buttonIndex == 1) {
            if ([_touchedTextCheckingResult.URL.scheme isEqualToString:@"mailto"]) {
                [[UIPasteboard generalPasteboard] setString:_touchedTextCheckingResult.URL.resourceSpecifier];
                
            } else {
                [[UIPasteboard generalPasteboard] setURL:_touchedTextCheckingResult.URL];
            }
        }
        
    } else if (NSTextCheckingTypePhoneNumber == _touchedTextCheckingResult.resultType) {
        if (buttonIndex == 0) {
            [[UIApplication sharedApplication] openURL:[NSURL URLWithString:[@"tel:" stringByAppendingString:_touchedTextCheckingResult.phoneNumber]]];
            
        } else if (buttonIndex == 1) {
            [[UIPasteboard generalPasteboard] setString:_touchedTextCheckingResult.phoneNumber];
        }
        
    } else if (NSTextCheckingTypeAddress == _touchedTextCheckingResult.resultType) {
        NSString *address = [_mutableAttributedString.string substringWithRange:_touchedTextCheckingResult.range];
        if (buttonIndex == 0) {
            [[UIApplication sharedApplication] openURL:[NSURL URLWithString:[[@"http://maps.google.com/maps?q=" stringByAppendingString:address] stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding]]];
            
        } else if (buttonIndex == 1) {
            [[UIPasteboard generalPasteboard] setString:address];
        }
        
    } else {
        // Unsupported data type only allows the user to copy.
        if (buttonIndex == 0) {
            NSString *text = [_mutableAttributedString.string substringWithRange:_touchedTextCheckingResult.range];
            [[UIPasteboard generalPasteboard] setString:text];
        }
    }
    
    _touchedTextCheckingResult = nil;
    [self setNeedsDisplay];
}

- (void)actionSheetCancel:(UIActionSheet *)actionSheet {
    _touchedTextCheckingResult = nil;
    [self setNeedsDisplay];
}

@end
