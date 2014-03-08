/*
 The MIT License (MIT)
 
 Copyright (c) 2013 Alexander Grebenyuk (github.com/kean).
 
 Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:
 
 The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.
 
 THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
 */

#import "DFFileStorage.h"

static const unsigned long long DFDiskCacheCapacityUnlimited = 0;

/*! DFFileStorage extension providing LRU cleanup.
 */
@interface DFDiskCache : DFFileStorage

/*! Maximum storage capacity. Default value is ULONG_MAX.
 @discussion Not a strict limit. Disk storage is actually cleaned up each time application resigns active (for iOS) and any time - (void)cleanup gets called.
 */
@property (nonatomic) unsigned long long capacity;

/*! Remaining disk usage after cleanup. The rate must be in the range of 0.0 to 1.0 where 1.0 represents full disk capacity.
 */
@property (nonatomic) CGFloat cleanupRate;

/*! Cleans up disk storage by removing entries by LRU algorithm.
 @discussion Cleanup algorithm runs only if max disk cache capacity is set to non-zero value. Calculates target size by multiplying disk capacity and cleanup rate. Files are removed according to LRU algorithm until cache size fits target size.
 */
- (void)cleanup;

/*! Returns path to caches directory.
 */
+ (NSString *)cachesDirectoryPath;

@end
