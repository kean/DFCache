/*
 The MIT License (MIT)
 
 Copyright (c) 2013 Alexander Grebenyuk (github.com/kean).
 
 Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:
 
 The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.
 
 THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
 */

#import "DFCache+UIImage.h"

@implementation DFCache (UIImage)

+ (instancetype)imageCache {
    static DFCache *_shared = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        _shared = [[DFCache alloc] initWithName:@"image_cache" memoryCache:[NSCache new]];
        _shared.diskCache.capacity = 1024 * 1024 * 120; // 120 Mb
        _shared.diskCache.cleanupRate = 0.6;
        _shared.memoryCache.totalCostLimit = 1024 * 1024 * 15; // 15 Mb
    });
    return _shared;
}

- (void)storeImage:(UIImage *)image imageData:(NSData *)data forKey:(NSString *)key {
    NSUInteger cost = DFCacheCostUIImage(image);
    if (data) {
        [self storeObject:image forKey:key cost:cost data:data];
    } else {
        [self storeObject:image forKey:key cost:cost encode:DFCacheEncodeUIImage];
    }
}

- (void)cachedImageForKey:(NSString *)key completion:(void (^)(UIImage *))completion {
    [self cachedObjectForKey:key decode:DFCacheDecodeUIImage cost:DFCacheCostUIImage completion:completion];
}

@end
