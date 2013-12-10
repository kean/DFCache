/*
 The MIT License (MIT)
 
 Copyright (c) 2013 Alexander Grebenyuk (github.com/kean).
 
 Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:
 
 The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.
 
 THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
 */

#import "DFLabelDefines.h"


/*! Text attachement allows you to add arbitary content to the DFLabel.
 @discussion There are two ways to render your content. You can either provide a CALayer by implementing - (CALayer *)layerWithSize: method. Or you can implement - (void)drawInContext:(CGContextRef)context rect:(CGRect)rect method to draw your content on CPU.
 */
@interface DFTextAttachement : NSObject

/*! Size of the attachement drawing context (layer).
 */
@property (nonatomic) CGSize size;

/*! Baseline offset is the position, where the attachement should be drawn in text. If positive then attachement (part of it) is displayed below baseline. Default value is 0.0.
 @discussion Baseline offset is substituted as an attachement character ascent. Baseline offset allows you to acheive any vertical alignment you want.
 */
@property (nonatomic) CGFloat baselineOffset;

/*! Attachement frame insets.
 */
@property (nonatomic) UIEdgeInsets insets;

/*! Returns a new layer that will be inserted into DFLabel layer.
 */
- (CALayer *)layerWithFrame:(CGRect)frame;

/*! Draws attachemenet content into CGContext.
 */
- (void)drawInContext:(CGContextRef)context rect:(CGRect)rect;

@end


@interface DFTextAttachement (Helpers)

- (CGSize)boxSize;
- (CGFloat)ascent;
- (CGFloat)descent;

@end


@interface DFTextAttachementImage : DFTextAttachement

@property (nonatomic, strong) UIImage *image;
@property (nonatomic) BOOL opaque;

@end