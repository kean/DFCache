/*
 The MIT License (MIT)
 
 Copyright (c) 2013 Alexander Grebenyuk (github.com/kean).
 
 Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:
 
 The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.
 
 THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
 */

#import "DFImageProcessing.h"
#import "DFImageFunctions.h"


@implementation DFImageProcessing

#pragma mark - Scaling

+ (UIImage *)imageWithImage:(UIImage *)image aspectFitSize:(CGSize)boundsSize {
    CGSize pixelSize = DFPixelSizeFromSize(boundsSize);
    return [self imageWithImage:image aspectFitPixelSize:pixelSize];
}

+ (UIImage *)imageWithImage:(UIImage *)image aspectFillSize:(CGSize)boundsSize {
    CGSize pixelSize = DFPixelSizeFromSize(boundsSize);
    return [self imageWithImage:image aspectFillPixelSize:pixelSize];
}

+ (UIImage *)imageWithImage:(UIImage *)image aspectFitPixelSize:(CGSize)boundsSize {
    CGSize imageSize = DFImageBitmapPixelSize(image);
    CGFloat scale = DFAspectFitScale(imageSize, boundsSize);
    if (scale < 1.0) {
        CGSize scaledSize = DFSizeScaled(imageSize, scale);
        CGSize pointSize = DFSizeFromPixelSize(scaledSize);
        return [self imageWithImage:image scaledToSize:pointSize];
    }
    return image;
}

+ (UIImage *)imageWithImage:(UIImage *)image aspectFillPixelSize:(CGSize)boundsSize {
    CGSize imageSize = DFImageBitmapPixelSize(image);
    CGFloat scale = DFAspectFillScale(imageSize, boundsSize);
    if (scale < 1.0) {
        CGSize scaledSize = DFSizeScaled(imageSize, scale);
        CGSize pointSize = DFSizeFromPixelSize(scaledSize);
        return [self imageWithImage:image scaledToSize:pointSize];
    }
    return image;
}

+ (UIImage *)imageWithImage:(UIImage *)image scaledToSize:(CGSize)boundsSize {
    CGSize roundedSize = CGSizeMake(floorf(boundsSize.width), floorf(boundsSize.height));
    UIGraphicsBeginImageContextWithOptions(roundedSize, NO, 0.0);
    [image drawInRect:CGRectMake(0, 0, roundedSize.width, roundedSize.height)];
    UIImage *newImage = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    return newImage;
}

#pragma mark - Decompression

+ (UIImage *)decompressedImageWithData:(NSData *)data orientation:(UIImageOrientation)orientation {
    if (!data) {
        return nil;
    }
#warning IMAGE DECOMPRESSION NOT IMPLEMENTED
    //UIImage *image = [DFJPEGTurbo jpegImageWithData:data orientation:orientation];
    //if (image) {
    //    return image;
    //}
    
    // Fallback to native methods (not jpeg)
    UIImage *image = [UIImage imageWithData:data];
    if (image) {
        return [UIImage imageWithCGImage:image.CGImage scale:[UIScreen mainScreen].scale orientation:image.imageOrientation];
    }
    return nil;
}


+ (UIImage *)decompressedImageWithData:(NSData *)data {
    return [self decompressedImageWithData:data orientation:UIImageOrientationUp];
}

@end
