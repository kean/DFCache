/*
 The MIT License (MIT)
 
 Copyright (c) 2013 Alexander Grebenyuk (github.com/kean).
 
 Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:
 
 The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.
 
 THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
 */

#import "DFImageProcessing.h"
#import "DFImageFunctions.h"
#import "DFJPEGTurbo.h"


@implementation DFImageProcessing

#pragma mark - Image Decoding

+ (UIImage *)decompressedImageWithData:(NSData *)data orientation:(UIImageOrientation)orientation {
   if (data == nil) {
      return nil;
   }
   
   UIImage *image = [DFJPEGTurbo jpegImageWithData:data orientation:orientation];
   if (image != nil) {
      return image;
   }
   
   // Fallback (not jpeg)
   image = [UIImage imageWithData:data];
   if (image) {
      return [UIImage imageWithCGImage:image.CGImage scale:[UIScreen mainScreen].scale orientation:image.imageOrientation];
   }
   
   return nil;
}


+ (UIImage *)decompressedImageWithData:(NSData *)data {
   return [self decompressedImageWithData:data orientation:UIImageOrientationUp];
}

@end
