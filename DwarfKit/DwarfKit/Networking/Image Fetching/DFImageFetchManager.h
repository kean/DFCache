/*
 The MIT License (MIT)
 
 Copyright (c) 2013 Alexander Grebenyuk (github.com/kean).
 
 Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:
 
 The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.
 
 THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
 */

#import <Foundation/Foundation.h>
#import "DFImageCaching.h"
#import "DFImageFetchHandler.h"
#import "DFImageFetchTask.h"
#import "DFTaskQueue.h"

/*!
 Image fetching with extreme performance.
 
 Key features:
 - Performance and scalability. Built entirely on top of GCD. DFImageFetchManager is able to maintain thousands of image requests/request cancellations per second. Even on older devices.
 - JPEG images are decompressed via libjpeg-turbo. JPEG decompression is 3-4 times faster then iOS codec.
 - Fully customisable cache (you can provide custom cache implementation or even use NSURLCache, cache implementation can be changed for the particular request, etc).
 - Resources with the same URL are never downloaded twice.
 */
@interface DFImageFetchManager : NSObject

/*! Initializes manager with specified name.
 @param name Name isn't used anywhere in the underlying implementation.
 @discussion Doesn't initialize image cache. You need to provide you own implementation (or use DFCache explicitly).
 */
- (id)initWithName:(NSString *)name;

@property (nonatomic, strong, readonly) NSString *name;
 
/*! Task queue that is used to execute image fetch tasks.
 */
@property (nonatomic, strong, readonly) DFTaskQueue *queue;

/*! Cache used by image fetch manager.
 @discussion If cache is set to nil then DFImageFetchTask uses shared NSURLCache.
 */
@property (nonatomic, strong) id<DFImageCaching> cache;

/*! Returns shared image fetch manager with initialized DFCache instance.
 */
+ (instancetype)shared;

/*! Fetches image with specified URL and calls DFImageFetchHandler object success or failure block on completion.
 */
- (DFImageFetchTask *)fetchImageWithURL:(NSString *)imageURL handler:(DFImageFetchHandler *)handler;

/*! Removes handler for specific image fetch task. If there are no handlers left fetch task is cancelled.
 */
- (void)cancelFetchingWithURL:(NSString *)imageURL handler:(DFImageFetchHandler *)handler;

/*! Prefetches image with specified URL.
 */
- (void)prefetchImageWithURL:(NSString *)imageURL;

@end
