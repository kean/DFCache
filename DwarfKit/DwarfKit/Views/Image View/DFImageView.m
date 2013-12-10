/*
 The MIT License (MIT)
 
 Copyright (c) 2013 Alexander Grebenyuk (github.com/kean).
 
 Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:
 
 The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.
 
 THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
 */

#import "DFCache+UIImage.h"
#import "DFImageFetchManager.h"
#import "DFImageView.h"
#import "UIImageView+Dwarf.h"


@implementation DFImageView {
   __weak DFTaskHandler *_handler;
}

- (void)setImageWithURL:(NSString *)imageURL {
   [self setImageWithURL:imageURL placeholder:nil];
}

- (void)setImageWithURL:(NSString *)imageURL placeholder:(UIImage *)placeholder {
   [self _cancelFetching];

   _imageURL = imageURL;
   
    UIImage *image = [[DFCache imageCache].memoryCache objectForKey:imageURL];
    if (image) {
        self.image = image;
        return;
    }
    
   if (placeholder) {
      self.image = placeholder;
   }
   
    [[DFCache imageCache] cachedImageForKey:imageURL completion:^(UIImage *image) {
        if (_imageURL != imageURL) {
            return;
        }
        if (image) {
            [self setImage:image animated:YES];
        } else {
            [self _fetchImage];
        }
    }];
}

- (void)_fetchImage {
    __weak DFImageView *weakSelf = self;
    DFTaskHandler *handler = [DFTaskHandler handlerWithCompletion:^(DFTask *task) {
        DFImageFetchTask *fetchTask = (id)task;
        if (fetchTask.image) {
            [weakSelf setImage:fetchTask.image animated:YES];
        }
    }];
    _handler = handler;
    [[DFImageFetchManager shared] fetchImageWithURL:_imageURL handler:handler];
}

- (void)_cancelFetching {
   if (_imageURL && _handler) {
       [[DFImageFetchManager shared] cancelFetchingWithURL:_imageURL handler:_handler];
      _handler = nil;
   }
}

@end
