//
//  SEDFImageView.m
//  Dwarf
//
//  Created by Alexander Grebenyuk on 8/12/13.
//  Copyright (c) 2013 Alexander Grebenyuk. All rights reserved.
//

#import "SDFImageView.h"
#import "DFImageFetchHandler.h"
#import "SDFImageFetchManager.h"
#import "UIImageView+Dwarf.h"


@implementation SDFImageView {
    NSString *_imageURL;
    __weak DFImageFetchHandler *_handler;
}


- (void)setImageWithURL:(NSString *)imageURL {
    [self cancelRequestOperation];
    
    _imageURL = imageURL;
    
    UIImage *image = [[SDFImageFetchManager sharedStressTestManager].cache imageForKey:imageURL];
    if (image) {
        self.image = image;
        return;
    }
    
    __weak DFImageView *weakSelf = self;
    DFImageFetchHandler *handler = [DFImageFetchHandler handlerWithSuccess:^(UIImage *image, DFResponseSource source) {
        DFImageView *strongSelf = weakSelf;
        if (strongSelf) {
            BOOL animated = (source != DFResponseSourceMemory);
            [self setImage:image animated:animated];
        }
    } failure:nil];
    
    [[SDFImageFetchManager sharedStressTestManager] fetchImageWithURL:imageURL handler:handler];
    _handler = handler;
}


- (void)cancelRequestOperation {
    if (_imageURL && _handler) {
        [[SDFImageFetchManager sharedStressTestManager] cancelFetchingWithURL:_imageURL handler:_handler];
        _handler = nil;
    }
}


@end
