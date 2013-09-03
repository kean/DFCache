/*
 The MIT License (MIT)
 
 Copyright (c) 2013 Alexander Grebenyuk (github.com/kean).
 
 Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:
 
 The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.
 
 THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
 */

#import "DFImageFetchManager.h"
#import "DFImageView.h"
#import "UIImageView+Dwarf.h"


@implementation DFImageView {
   __weak DFImageFetchHandler *_handler;
}


- (void)setImageWithURL:(NSString *)imageURL {
   [self setImageWithURL:imageURL placeholder:nil];
}


- (void)setImageWithURL:(NSString *)imageURL placeholder:(UIImage *)placeholder {
   [self cancelRequestOperation];

   _imageURL = imageURL;
   
   UIImage *image = [[DFImageFetchManager shared].cache imageForKey:imageURL];
   if (image) {
      self.image = image;
      return;
   }
   
   if (placeholder) {
      self.image = placeholder;
   }
   
   __weak DFImageView *weakSelf = self;
   DFImageFetchHandler *handler = [DFImageFetchHandler handlerWithSuccess:^(UIImage *image, DFResponseSource source) {
      DFImageView *strongSelf = weakSelf;
      if (strongSelf) {
         BOOL animated = (source != DFResponseSourceMemory);
         [self setImage:image animated:animated];
      }
   } failure:nil];
   
    [[DFImageFetchManager shared] fetchImageWithURL:imageURL handler:handler];
   _handler = handler;
}


- (void)cancelRequestOperation {
   if (_imageURL && _handler) {
      [[DFImageFetchManager shared] cancelFetchingWithURL:_imageURL handler:_handler];
      _handler = nil;
   }
}

@end
