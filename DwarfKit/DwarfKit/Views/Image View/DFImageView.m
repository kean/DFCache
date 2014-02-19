/*
 The MIT License (MIT)
 
 Copyright (c) 2013 Alexander Grebenyuk (github.com/kean).
 
 Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:
 
 The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.
 
 THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
 */

#import "DFImageView.h"
#import "DFURLImageProvider.h"
#import "DFURLSession.h"


@implementation DFImageView

- (void)setImageWithURL:(NSString *)imageURL {
    [self setImageWithURL:imageURL placeholder:nil];
}

- (void)setImageWithURL:(NSString *)imageURL placeholder:(UIImage *)placeholder {
    [self _cancelFetching];
    
    _imageURL = imageURL;
    
    UIImage *image = [[DFURLImageProvider shared] memoryCachedImageWithURL:imageURL];
    if (image) {
        self.image = image;
        return;
    }
    
    if (placeholder) {
        self.image = placeholder;
    }
    
    [[DFURLImageProvider shared] cachedImageWithURL:imageURL completion:^(UIImage *image) {
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
    [[DFURLImageProvider shared] imageWithURL:_imageURL handler:self completion:^(UIImage *image, NSError *error, DFURLSessionTask *task) {
        [weakSelf setImage:image animated:YES];
    }];
}

- (void)_cancelFetching {
    if (_imageURL) {
        [[DFURLImageProvider shared] cancelImageRequestWithURL:_imageURL handler:self];
    }
}

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
