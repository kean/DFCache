/*
 The MIT License (MIT)
 
 Copyright (c) 2013 Alexander Grebenyuk (github.com/kean).
 
 Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:
 
 The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.
 
 THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
 */

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
