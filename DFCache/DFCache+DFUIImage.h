// The MIT License (MIT)
//
// Copyright (c) 2014 Alexander Grebenyuk (github.com/kean).
//
// Permission is hereby granted, free of charge, to any person obtaining a copy
// of this software and associated documentation files (the "Software"), to deal
// in the Software without restriction, including without limitation the rights
// to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
// copies of the Software, and to permit persons to whom the Software is
// furnished to do so, subject to the following conditions:
//
// The above copyright notice and this permission notice shall be included in
// all copies or substantial portions of the Software.
//
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
// FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
// AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
// LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
// OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
// THE SOFTWARE.

#import "DFCache.h"
#import "DFCacheBlocks.h"
#import "DFCacheImageDecoder.h"

static const DFCacheEncodeBlock DFCacheEncodeUIImage = ^NSData *(UIImage *image){
    return UIImageJPEGRepresentation(image, 1.0);
};

static const DFCacheDecodeBlock DFCacheDecodeUIImage = ^UIImage *(NSData *data) {
    UIImage *image = [[UIImage alloc] initWithData:data scale:[UIScreen mainScreen].scale];
    return [DFCacheImageDecoder decodedImage:image];
};

static const DFCacheCostBlock DFCacheCostUIImage = ^NSUInteger(id object){
    if (![object isKindOfClass:[UIImage class]]) {
        return 0;
    }
    UIImage *image = (UIImage *)object;
    return CGImageGetWidth(image.CGImage) * CGImageGetHeight(image.CGImage) * 4;
};


@interface DFCache (DFUIImage)

/*! Stores image into memory cache. Stores image data into disk cache. If image data is nil DFCacheEncodeUIImage block is used.
 */
- (void)storeImage:(UIImage *)image imageData:(NSData *)data forKey:(NSString *)key;

/*! Retreives object from disk asynchronously using DFCacheDecodeUIImage and DFCacheCostUIImage.
 */
- (void)cachedImageForKey:(NSString *)key completion:(void (^)(UIImage *image))completion;

/*! Retreives object from disk synchronously using DFCacheDecodeUIImage and DFCacheCostUIImage.
 */
- (UIImage *)cachedImageForKey:(NSString *)key;

@end
