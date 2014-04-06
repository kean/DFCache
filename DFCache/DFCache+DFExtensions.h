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

/* Set of methods extending DFCache functionality. API to retrieve cached objects in batches.
*/
@interface DFCache (DFCacheExtensions)

#pragma mark - Read (Batching)

/*! Reads data for provided keys.
 @param keys Array of unique keys.
 @param decode Decoding block returning object from data.
 @param cost Cost block returning cost for memory cache.
 @param completion Completion block. Batch dictionary contains key : data pairs read from disk cache.
 */
- (void)cachedDataForKeys:(NSArray *)keys completion:(void (^)(NSDictionary *batch))completion;

/*! Reads objects for provided keys.
 @param keys Array of unique keys.
 @param decode Decoding block returning object from data.
 @param cost Cost block returning cost for memory cache.
 @param completion Completion block. Batch dictionary contains key : object pairs retrieved from receiver.
 */
- (void)cachedObjectsForKeys:(NSArray *)keys
                      decode:(DFCacheDecodeBlock)decode
                        cost:(DFCacheCostBlock)cost
                  completion:(void (^)(NSDictionary *batch))completion;

/*! Reads first found object for provided keys.
 @param key The unique key.
 @param decode Decoding block returning object from data.
 @param cost Cost block returning cost for memory cache.
 @param completion Completion block.
 */
- (void)cachedObjectForAnyKey:(NSArray *)keys
                       decode:(DFCacheDecodeBlock)decode
                         cost:(DFCacheCostBlock)cost
                   completion:(void (^)(id object, NSString *key))completion;

@end
