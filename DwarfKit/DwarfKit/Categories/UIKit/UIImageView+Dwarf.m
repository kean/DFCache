//
//  UIImageView+Dwarf.m
//  Dwarf
//
//  Created by Alexander Grebenyuk on 8/11/13.
//  Copyright (c) 2013 Alexander Grebenyuk. All rights reserved.
//

#import "DFImageFetchManager.h"
#import "UIImageView+Dwarf.h"
#import <QuartzCore/QuartzCore.h>
#import <objc/runtime.h>


@implementation UIImageView (Dwarf)

#pragma mark - Animations

- (void)setImage:(UIImage *)image animated:(BOOL)animated {
   self.image = image;
   if (animated) {
      CABasicAnimation *animation = [CABasicAnimation animationWithKeyPath:@"opacity"];
      animation.keyPath = @"opacity";
      animation.fromValue = @0.f;
      animation.toValue = @1.f;
      animation.duration = 0.1f;
      [self.layer addAnimation:animation forKey:@"opacity"];
   }
}

@end
