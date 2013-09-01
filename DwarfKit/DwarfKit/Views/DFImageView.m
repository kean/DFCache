//
//  DFImageView.m
//  Dwarf
//
//  Created by Alexander Grebenyuk on 8/11/13.
//  Copyright (c) 2013 Alexander Grebenyuk. All rights reserved.
//

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
