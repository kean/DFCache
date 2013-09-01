//
//  DFJPEGTurbo.h
//  Dwarf
//
//  Created by Alexander Grebenyuk on 12.08.13.
//  Copyright (c) 2013 Alexander Grebenyuk. All rights reserved.
//

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
