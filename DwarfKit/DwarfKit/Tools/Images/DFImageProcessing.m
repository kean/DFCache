//
//  DFImageProcessing.m
//  Dwarf
//
//  Created by Alexander Grebenyuk on 7/14/13.
//  Copyright (c) 2013 Alexander Grebenyuk. All rights reserved.
//

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
