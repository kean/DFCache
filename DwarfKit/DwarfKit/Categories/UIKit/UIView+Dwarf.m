//
//  UIView+Dwarf.m
//  Dwarf
//
//  Created by Alexander Grebenyuk on 7/14/13.
//  Copyright (c) 2013 Alexander Grebenyuk. All rights reserved.
//

#import "UIView+Dwarf.h"

@implementation UIView (Dwarf)

- (CGFloat)width {
   return self.frame.size.width;
}


- (void)setWidth:(CGFloat)width {
   if (self.width != width) {
      CGRect frame = self.frame;
      frame.size.width = width;
      self.frame = frame;
   }
}


- (CGFloat)height {
   return self.frame.size.height;
}


- (void)setHeight:(CGFloat)height {
   if (self.height != height) {
      CGRect frame = self.frame;
      frame.size.height = height;
      self.frame = frame;
   }
}


- (CGFloat)left {
   return self.frame.origin.x;
}


- (void)setLeft:(CGFloat)left {
   if (self.left != left) {
      CGRect frame = self.frame;
      frame.origin.x = left;
      self.frame = frame;
   }
}


- (CGFloat)top {
   return self.frame.origin.y;
}


- (void)setTop:(CGFloat)top {
   if (self.top != top) {
      CGRect frame = self.frame;
      frame.origin.y = top;
      self.frame = frame;
   }
}


- (CGFloat)right {
   return self.left + self.width;
}


- (void)setRight:(CGFloat)right {
   if (self.right != right) {
      CGRect frame = self.frame;
      frame.origin.x = right - frame.size.width;
      self.frame = frame;
   }
}


- (CGFloat)bottom {
   return self.top + self.height;
}


- (void)setBottom:(CGFloat)bottom {
   if (self.bottom != bottom) {
      CGRect frame = self.frame;
      frame.origin.y = bottom - frame.size.height;
      self.frame = frame;
   }
}


- (CGSize)size {
   return self.frame.size;
}


- (void)setSize:(CGSize)size {
   CGRect frame = self.frame;
   frame.size = size;
   self.frame = frame;
}

@end
