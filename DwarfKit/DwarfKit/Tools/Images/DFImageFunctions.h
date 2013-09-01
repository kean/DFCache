//
//  DFImageFunctions.h
//  Dwarf
//
//  Created by Alexander Grebenyuk on 12.08.13.
//  Copyright (c) 2013 Alexander Grebenyuk. All rights reserved.
//

#import <Foundation/Foundation.h>

static inline CGFloat DFAspectFitScale(CGSize imageSize, CGSize boundsSize) {
   CGFloat scaleWidth = boundsSize.width / imageSize.width;
   CGFloat scaleHeight = boundsSize.height / imageSize.height;
   return MIN(scaleWidth, scaleHeight);
}


static inline CGFloat DFAspectFillScale(CGSize imageSize, CGSize boundsSize) {
   CGFloat scaleWidth = boundsSize.width / imageSize.width;
   CGFloat scaleHeight = boundsSize.height / imageSize.height;
   return MAX(scaleWidth, scaleHeight);
}