/*
 The MIT License (MIT)
 
 Copyright (c) 2013 Alexander Grebenyuk (github.com/kean).
 
 Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:
 
 The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.
 
 THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
 */

#import "SDFImageView.h"
#import "SDFImageFetchManager.h"
#import "DFCache.h"
#import "UIImageView+Dwarf.h"


@implementation SDFImageView {
    __weak DFImageFetchHandler *_handler;
}

- (void)_fetchImage {
    __weak DFImageView *weakSelf = self;
    DFImageFetchHandler *handler = [DFImageFetchHandler handlerWithSuccess:^(UIImage *image) {
        [weakSelf setImage:image animated:YES];
    } failure:^(NSError *error) {
        // Do nothing
    }];
    _handler = handler;
    
    DFImageFetchTask *task = [[SDFImageFetchManager shared] fetchImageWithURL:self.imageURL handler:handler];
    [task setCachingBlock:^(UIImage *image, NSData *data, NSString *lastModified) {
        DFCache *cache = [DFCache imageCache];
        [cache storeImage:image imageData:data forKey:self.imageURL];
    }];
}


- (void)_cancelFetching {
    if (self.imageURL && _handler) {
        [[SDFImageFetchManager shared] cancelFetchingWithURL:self.imageURL handler:_handler];
        _handler = nil;
    }
}


@end
