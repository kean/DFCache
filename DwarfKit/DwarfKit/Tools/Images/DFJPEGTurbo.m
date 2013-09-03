/*
 The MIT License (MIT)
 
 Copyright (c) 2013 Alexander Grebenyuk (github.com/kean).
 
 Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:
 
 The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.
 
 THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
 */

#import "DFJPEGTurbo.h"
#import "DFImageFunctions.h"
#import "turbojpeg.h"


@implementation DFJPEGTurbo

static void releaseData (void *info, const void *data, size_t size) {
    free(info);
}

#pragma mark - Decompression

+ (UIImage *)jpegImageWithData:(NSData *)data {
    return [self jpegImageWithData:data
                       orientation:UIImageOrientationUp
                       desiredSize:CGSizeZero
                           scaling:0
                          rounding:0];
}


+ (UIImage *)jpegImageWithData:(NSData *)data
                   orientation:(UIImageOrientation)orientation {
    return [self jpegImageWithData:data
                       orientation:orientation
                       desiredSize:CGSizeZero
                           scaling:0
                          rounding:0];
}


static inline tjscalingfactor DFScalingFactor(int width, int height, CGSize desiredSize, DFJPEGTurboScaling scaling, DFJPEGTurboRounding rounding) {
    tjscalingfactor resultFactor = { .num = 1, .denom = 1 };
    
    // Calculate desired scale
    CGFloat scale;
    CGSize imageSize = CGSizeMake(width, height);
    switch (scaling) {
        case DFJPEGTurboScalingAspectFit:
            scale = DFAspectFitScale(imageSize, desiredSize);
            break;
        case DFJPEGTurboScalingAspectFill:
            scale = DFAspectFillScale(imageSize, desiredSize);
            break;
        case DFJPEGTurboScalingNone:
        default:
            scale = 1.0;
            break;
    }
    
    if (scale >= 1.0) {
        return resultFactor;
    }
    
    int fitWidth = width * scale;
    
    int pickedWidth = width;
    
    // Pick best fitting scale factor
    int num;
    tjscalingfactor *factors = tjGetScalingFactors(&num);
    for (int i = 0; i < num; i++) {
        tjscalingfactor factor = factors[i];
        int scaledWidth = TJSCALED(width, factor);
        int widthDiff = abs(fitWidth - scaledWidth);
        int pickedWidthDiff = abs(fitWidth - pickedWidth);
        
        if (widthDiff < pickedWidthDiff) {
            switch (rounding) {
                case DFJPEGTurboRoundingCeil:
                    if (scaledWidth >= fitWidth) {
                        pickedWidth = scaledWidth;
                        resultFactor = factor;
                    }
                    break;
                case DFJPEGTurboRoundingFloor:
                    if (scaledWidth <= fitWidth) {
                        pickedWidth = scaledWidth;
                        resultFactor = factor;
                    }
                    break;
                case DFJPEGTurboRoundingRound:
                    pickedWidth = scaledWidth;
                    resultFactor = factor;
                    break;
                default:
                    break;
            }
        }
    }
    
    return resultFactor;
}


+ (UIImage *)jpegImageWithData:(NSData *)data
                   orientation:(UIImageOrientation)orientation
                   desiredSize:(CGSize)desiredSize
                       scaling:(DFJPEGTurboScaling)scaling
                      rounding:(DFJPEGTurboRounding)rounding {
    if (data == nil) {
        return nil;
    }
    
    tjhandle decoder = tjInitDecompress();
    
    unsigned char *jpegBuf = (unsigned char *)data.bytes;
    unsigned long jpegSize = data.length;
    int width, height, jpegSubsamp;
    
    int result = tjDecompressHeader2(decoder, jpegBuf, jpegSize, &width, &height, &jpegSubsamp);
    if (result < 0) {
        return nil;
    }
    
    if (scaling != DFJPEGTurboScalingNone) {
        tjscalingfactor factor = DFScalingFactor(width, height, desiredSize, scaling, rounding);
        width = TJSCALED(width, factor);
        height = TJSCALED(height, factor);
    }
    
    int pitch = width * 4;
    size_t capacity = height * pitch;
    unsigned char *imageData = calloc(capacity, sizeof(unsigned char));
    
    result = tjDecompress2(decoder, jpegBuf, jpegSize, imageData, width, pitch, height, TJPF_RGBA, 0);
    if (result < 0) {
        free(imageData);
        return nil;
    }
    
    CGDataProviderRef imageDataProvider = CGDataProviderCreateWithData(imageData, imageData, capacity, &releaseData);
    CGColorSpaceRef colorspace = CGColorSpaceCreateDeviceRGB();
    CGImageRef image = CGImageCreate(width, height, 8, 32, pitch, colorspace, kCGBitmapByteOrderDefault | kCGImageAlphaNoneSkipLast, imageDataProvider, NULL, NO, kCGRenderingIntentDefault);
    
    UIImage *decompressedImage = [UIImage imageWithCGImage:image scale:[UIScreen mainScreen].scale orientation:orientation];
    
    CGImageRelease(image);
    CGDataProviderRelease(imageDataProvider);
    CGColorSpaceRelease(colorspace);
    
    return decompressedImage;
}

@end
