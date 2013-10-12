/*
 The MIT License (MIT)
 
 Copyright (c) 2013 Alexander Grebenyuk (github.com/kean).
 
 Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:
 
 The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.
 
 THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
 */

#import "DFCache.h"
#import "DFImageFetchManager.h"
#import "DFImageProviderTask.h"


@implementation DFImageProviderTask {
    __weak DFImageFetchHandler *_fetchHandler;
    __weak DFImageFetchTask *_fetchTask;
}

- (id)initWithURL:(NSString *)imageURL {
    if (self = [super init]) {
        _imageURL = imageURL;
    }
    return self;
}

- (NSUInteger)hash {
    return [_imageURL hash];
}

#pragma mark - Task Implementation

- (void)execute {
    DFCache *cache = [DFCache imageCache];
    _image = [cache.memoryCache objectForKey:_imageURL];
    if (_image) {
        _source = DFResponseSourceMemory;
        [self finish];
        return;
    }
    
    [cache cachedImageForKey:_imageURL completion:^(UIImage *image) {
        if (image) {
            _image = image;
            _source = DFResponseSourceDisk;
            [self finish];
        } else {
            [self _fetchImage];
        }
    }];
}

- (void)cancel {
    [super cancel];
    if (_fetchHandler) {
        [[DFImageFetchManager shared] cancelFetchingWithURL:_imageURL handler:_fetchHandler];
        _fetchHandler = nil;
        [self finish];
    }
}

#pragma mark - Image Fetching

- (void)_fetchImage {
    if ([self isCancelled]) {
        [self finish];
        return;
    }
    
    DFImageFetchHandler *handler = [DFImageFetchHandler handlerWithSuccess:^(UIImage *image) {
        _image = image;
        [self finish];
    } failure:^(NSError *error) {
        _error = error;
        [self finish];
    }];
    _fetchHandler = handler;
    
    _fetchTask = [[DFImageFetchManager shared] fetchImageWithURL:_imageURL handler:handler];
}

- (BOOL)isFetching {
    return _fetchTask.isExecuting;
}

@end
