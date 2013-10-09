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
    NSString *_imageURL;
    __weak DFImageProviderHandler *_handler;
}


- (void)setImageWithURL:(NSString *)imageURL {
    [self cancelRequestOperation];
    
    _imageURL = imageURL;
    
    UIImage *image = [[DFCache imageCache].memoryCache objectForKey:imageURL];
    if (image) {
        self.image = image;
        return;
    }
    
    __weak DFImageView *weakSelf = self;
    DFImageProviderHandler *handler = [DFImageProviderHandler handlerWithSuccess:^(UIImage *image, DFResponseSource source) {
        DFImageView *strongSelf = weakSelf;
        if (strongSelf) {
            BOOL animated = (source != DFResponseSourceMemory);
            [self setImage:image animated:animated];
        }
    } failure:nil];
    
    [[SDFImageFetchManager sharedStressTestManager] requestImageWithURL:imageURL handler:handler];
    _handler = handler;
}


- (void)cancelRequestOperation {
    if (_imageURL && _handler) {
        [[SDFImageFetchManager sharedStressTestManager] cancelRequestWithURL:_imageURL handler:_handler];
        _handler = nil;
    }
}


@end
