/*
 The MIT License (MIT)
 
 Copyright (c) 2013 Alexander Grebenyuk (github.com/kean).
 
 Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:
 
 The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.
 
 THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
 */

/*! Caching protocol used by DFImageFetchManager. DFCache implements this protocol.
 */

@protocol DFImageCaching <NSObject>

/*! Returns image from memory cache.
 */
- (UIImage *)imageForKey:(NSString *)key;

/*! Calls completion block on the queue with image from disk cache. Doesn't check memory cache.
 @param key The unique key.
 @param queue Queue that is used to execute completion block on.
 @param completion Completion block that gets called on the main queue (or on your queue if queue parameter isn't NULL).
 */
- (void)cachedImageForKey:(NSString *)key
               completion:(void (^)(UIImage *image))completion;

/*! Store image in either memory or disk cache (or both).
 @param image Image to store in memory cache.
 @param imageData Image data to store in disk cache.
 @param key The unique key.
 */
- (void)storeImage:(UIImage *)image
         imageData:(NSData *)imageData
            forKey:(NSString *)key;

@end
