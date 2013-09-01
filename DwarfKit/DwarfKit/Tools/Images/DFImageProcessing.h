//
//  DFImageProcessing.h
//  Dwarf
//
//  Created by Alexander Grebenyuk on 7/14/13.
//  Copyright (c) 2013 Alexander Grebenyuk. All rights reserved.
//


@interface DFImageProcessing : NSObject

#pragma mark - Image Decoding

+ (UIImage *)decompressedImageWithData:(NSData *)data;
+ (UIImage *)decompressedImageWithData:(NSData *)data orientation:(UIImageOrientation)orientation;

@end


#pragma mark - Intermediate Calculations

static inline CGSize DFPixelSizeFromSize(CGSize size) {
   CGFloat scale = [UIScreen mainScreen].scale;
   return CGSizeMake(size.width * scale, size.height * scale);
}


static inline CGSize DFSizeFromPixelSize(CGSize size) {
   CGFloat scale = [UIScreen mainScreen].scale;
   return CGSizeMake(size.width / scale, size.height / scale);
}


static inline CGSize DFImageSize(UIImage *image) {
   CGFloat scale = [UIScreen mainScreen].scale;
   if (image.scale == scale) {
      return image.size;
   } else {
      return CGSizeMake(image.size.width / scale, image.size.height / scale);
   }
}


static inline CGSize DFImageBitmapPixelSize(UIImage *image) {
   return CGSizeMake(CGImageGetWidth(image.CGImage), CGImageGetHeight(image.CGImage));
}


static inline CGSize DFImagePixelSize(UIImage *image) {
   return CGSizeMake(image.size.width * image.scale, image.size.height * image.scale);
}


static inline CGSize DFSizeScaled(CGSize size, CGFloat scale) {
   return CGSizeMake(size.width * scale, size.height * scale);
}


static inline CGSize DFRoundedEvenedSize(CGSize size) {
   NSInteger width = size.width;
   if (width % 2 != 0) width += 1;
   NSInteger height = size.height;
   if (height % 2 != 0) height += 1;
   return CGSizeMake(width, height);
}
