// The MIT License (MIT)
//
// Copyright (c) 2014 Alexander Grebenyuk (github.com/kean).
//
// Permission is hereby granted, free of charge, to any person obtaining a copy
// of this software and associated documentation files (the "Software"), to deal
// in the Software without restriction, including without limitation the rights
// to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
// copies of the Software, and to permit persons to whom the Software is
// furnished to do so, subject to the following conditions:
//
// The above copyright notice and this permission notice shall be included in
// all copies or substantial portions of the Software.
//
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
// FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
// AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
// LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
// OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
// THE SOFTWARE.

#import "DFCacheImageDecoder.h"
#import <CoreGraphics/CoreGraphics.h>

@implementation DFCacheImageDecoder

#if (__IPHONE_OS_VERSION_MIN_REQUIRED)

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

#endif

@end
