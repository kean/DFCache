// The MIT License (MIT)
//
// Copyright (c) 2015 Alexander Grebenyuk (github.com/kean).

#import "DFCacheImageDecoder.h"
#import <CoreGraphics/CoreGraphics.h>

#if TARGET_OS_IOS || TARGET_OS_TV
@implementation DFCacheImageDecoder

+ (UIImage *)decompressedImageWithData:(NSData *)data {
    return [self _decompressedImage:(data ? [UIImage imageWithData:data scale:[UIScreen mainScreen].scale] : nil)];
}

+ (UIImage *)_decompressedImage:(UIImage *)image {
    if (!image) {
        return nil;
    }
    if (image.images) {
        return image;
    }
    CGImageRef imageRef = image.CGImage;
    CGSize imageSize = CGSizeMake(CGImageGetWidth(imageRef), CGImageGetHeight(imageRef));
    CGColorSpaceRef colorSpaceRef = CGColorSpaceCreateDeviceRGB();
    CGContextRef contextRef = CGBitmapContextCreate(NULL, (size_t)imageSize.width, (size_t)imageSize.height, CGImageGetBitsPerComponent(imageRef), 0, colorSpaceRef, (kCGBitmapByteOrderDefault | kCGImageAlphaPremultipliedFirst));
    if (colorSpaceRef) {
        CGColorSpaceRelease(colorSpaceRef);
    }
    if (!contextRef) {
        return image;
    }
    CGContextDrawImage(contextRef, (CGRect){CGPointZero, imageSize}, imageRef);
    CGImageRef decompressedImageRef = CGBitmapContextCreateImage(contextRef);
    CGContextRelease(contextRef);
    UIImage *decompressedImage = [UIImage imageWithCGImage:decompressedImageRef scale:image.scale orientation:image.imageOrientation];
    if (decompressedImageRef) {
        CGImageRelease(decompressedImageRef);
    }
    return decompressedImage;
}

@end
#endif
