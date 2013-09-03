/*
 The MIT License (MIT)
 
 Copyright (c) 2013 Alexander Grebenyuk (github.com/kean).
 
 Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:
 
 The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.
 
 THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
 */

#import <Foundation/Foundation.h>

/*! Defines algorithm to compute scale factor based on the image size and the desired size.
 */
typedef NS_ENUM(NSUInteger, DFJPEGTurboScaling) {
    DFJPEGTurboScalingNone,       // Do not scale
    DFJPEGTurboScalingAspectFit,  // Scale image to fit size
    DFJPEGTurboScalingAspectFill  // Scale image to fill size
};

/*! Defines algorithm that is used to pick scaling factor from libjpeg-turbo available scaling factors (1/2, 1/4, 1/8 etc).
 */
typedef NS_ENUM(NSUInteger, DFJPEGTurboRounding) {
    DFJPEGTurboRoundingFloor, // Scaled image width >= desired image width.
    DFJPEGTurboRoundingCeil,  // Scaled image width <= desired image width.
    DFJPEGTurboRoundingRound  // Scaled image width if as close to desired image width as possible.
};

/*! Objective-C libjpeg-turbo wrapper
 */
@interface DFJPEGTurbo : NSObject

#pragma mark - Decompression

/*! Decompresses JPEG image data. Returns nil for non-JPEG data formats.
 @param data JPEG image data.
 @param orientation Image orientation of image data.
 @param desiredSize Bounds size that is used to aspect fit image.
 @discussion Scaling: libjpeg-turbo provides several scaling factors (1/2, 1/4, 1/8 etc). There is no way to get image the exact disired size you want. There are multiple options (scaling & rounding) to define the algorithm to pick scaling factor.
 */
+ (UIImage *)jpegImageWithData:(NSData *)data
                   orientation:(UIImageOrientation)orientation
                   desiredSize:(CGSize)desiredSize
                       scaling:(DFJPEGTurboScaling)scaling
                      rounding:(DFJPEGTurboRounding)rounding;

+ (UIImage *)jpegImageWithData:(NSData *)data;
+ (UIImage *)jpegImageWithData:(NSData *)data
                   orientation:(UIImageOrientation)orientation;

@end
