/*
 The MIT License (MIT)
 
 Copyright (c) 2013 Alexander Grebenyuk (github.com/kean).
 
 Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:
 
 The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.
 
 THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
 */

#import "DFLabelDelegate.h"
#import "DFTextAttachement.h"
#import "NSAttributedString+DF.h"
#import "NSMutableAttributedString+DF.h"


/*! The DFLabel class provides support for displaying rich text with selectable links.
 @discussion NSLineBreakModeHeadTruncation and NSLineBreakModeMiddleTruncation only apply to single lines and will not wrap the label regardless of the numberOfLines property. To wrap lines with any of these line break modes you must explicitly add newline characters to the string.
 @warning NSLineBreakModeTruncationTail is handled manually.
 */
NS_CLASS_AVAILABLE(10_8, 6_0)
@interface DFLabel : UILabel

@property (nonatomic, weak) id<DFLabelDelegate> delegate;

#warning Shadow blut might be broken.
@property (nonatomic) CGFloat shadowBlur; // Default: 0
@property (nonatomic) NSString *ellipsesString;

/*! Return dictionary containing current label text attributes.
 @discussion Label text attributes are: text color, text font, paragraph style.
 */
@property (nonatomic, readonly) NSDictionary *textAttributes;

/*! Setting data detector to not nil value enables DFLabel data detection.
 @discussion Data detection is asynchronous.
 */
@property (nonatomic) NSDataDetector *dataDetector;

/*! The attributes to apply to detected data.
 @discussion The default attributes specify blue text with a single underline and the pointing hand cursor.
 */
@property (nonatomic) NSDictionary *dataTextAttributes;

/*! Highlight color, displayed when user selectes detected data. Default is light gray color.
 */
@property (nonatomic) UIColor *dataHighlightColor;

@property (nonatomic, readonly) UITapGestureRecognizer *tapGestureRecognizer;

- (NSTextCheckingResult *)linkAtPoint:(CGPoint)point;
- (void)addLink:(NSURL *)urlLink range:(NSRange)range;

@end
