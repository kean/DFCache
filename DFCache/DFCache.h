/*
 The MIT License (MIT)
 
 Copyright (c) 2013 Alexander Grebenyuk (github.com/kean).
 
 Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:
 
 The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.
 
 THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
 */

#import "DFDiskCache.h"
#import "DFCacheBlocks.h"

/*! Extended attribute name used to store metadata (see NSURL+DFExtendedFileAttributes).
 */
extern NSString *const DFCacheAttributeMetadataKey;

/* DFCache key features:
 - Asynchronous composite in-memory and on-disk cache.
 - Encoding, decoding and cost calculation implemented using blocks. Store any kind of Objective-C objects or manipulate data directly (see DFFileStorage).
 - LRU cleanup (discard least recently used items first).
 - Custom metadata implemented on top on UNIX extended file attributes.
 - Thoroughly tested. Written for and used heavily in the iOS application with more than half a million active users.
 - Concise and extensible API.
 */

/*! Asynchronous composite in-memory and on-disk cache. 
 @discussion Uses NSCache for in-memory caching and DFDiskCache for on-disk caching. Extends DFDiskCache functionality by providing API for associating custom metadata with cache entries.
 */
@interface DFCache : NSObject

/*! Initializes and returns cache with provided disk and memory cache.
 @param diskCache Disk cache. Must not be nil.
 @param memoryCache Memory cache. Pass nil to disable memory caching.
 */
- (id)initWithDiskCache:(DFDiskCache *)diskCache memoryCache:(NSCache *)memoryCache;

/*! Convenience method. Initializes and returns cache with provided name and memory cache.
 @param name Name is used to initialize disk cache.
 @param memoryCache Memory cache. Pass nil to disable memory caching.
 */
- (id)initWithName:(NSString *)name memoryCache:(NSCache *)memoryCache;

/*! Convenience method. Initializes and returns cache with provided name. Creates both disk and memory cache.
 @param name Name is used to initialize disk cache.
 */
- (id)initWithName:(NSString *)name;

/*! Returns memory cache or nil if cache was initialized without the memory cache.
 */
@property (nonatomic, readonly) NSCache *memoryCache;

/*! Returns disk cache used by DFCache instance.
 */
@property (nonatomic, readonly) DFDiskCache *diskCache;

/*! Internal disk queue used to dispatch blocks operating on disk cache.
 */
@property (nonatomic) dispatch_queue_t ioQueue;

/*! Internal processing queue used to dispatch decoding blocks. Etc.
 */
@property (nonatomic) dispatch_queue_t processingQueue;

#pragma mark - Read

/*! Reads object from disk.
 @param key The unique key.
 @param decode Decoding block returning object from data.
 @param cost Cost block returning cost for memory cache.
 @param completion Completion block.
 */
- (void)cachedObjectForKey:(NSString *)key
                    decode:(DFCacheDecodeBlock)decode
                      cost:(DFCacheCostBlock)cost
                completion:(void (^)(id object))completion;

/*! Returns object from disk synchorounsly.
 @param key The unique key.
 @param decode Decoding block returning object from data.
 @param cost Cost block returning cost for memory cache.
 */
- (id)cachedObjectForKey:(NSString *)key
                  decode:(DFCacheDecodeBlock)decode
                    cost:(DFCacheCostBlock)cost;

#pragma mark - Write

/*! Stores object into memory cache. Stores data into disk cache.
 @param object The object to store into memory cache.
 @param key The unique key.
 @param cost The cost with which to associate the object (used by memory cache).
 @param data Data to store into disk cache.
 */
- (void)storeObject:(id)object
             forKey:(NSString *)key
               cost:(NSUInteger)cost
               data:(NSData *)data;

/*! Stores object into memory cache. Stores data representation provided by the transformation block into disk cache.
 @param object The object to store into memory cache.
 @param key The unique key.
 @param cost The cost with which to associate the object (used by memory cache).
 @param encode Encoder block returning object's data representation.
 */
- (void)storeObject:(id)object
             forKey:(NSString *)key
               cost:(NSUInteger)cost
             encode:(DFCacheEncodeBlock)encode;

/*! Stores object into memory cache. Calculate cost using provided block (if block is not nil).
 @param object The object to store into memory cache.
 @param key The unique key.
 @param cost The cost with which to associate the object (used by memory cache).
 */
- (void)storeObject:(id)object forKey:(NSString *)key cost:(DFCacheCostBlock)cost;

#pragma mark - Remove

/*! Removes object from both disk and memory cache.
 */
- (void)removeObjectsForKeys:(NSArray *)keys;
- (void)removeObjectForKey:(NSString *)key;
- (void)removeAllObjects;

#pragma mark - Metadata

/*! Returns copy of metadata for provided key.
 @param key The unique key.
 @return Copy of metadata for key.
 */
- (NSDictionary *)metadataForKey:(NSString *)key;

/*! Sets metadata for provided key.
 @param metadata Dictionary with metadata.
 @param key The unique key.
 */
- (void)setMetadata:(NSDictionary *)metadata forKey:(NSString *)key;

/*! Sets metadata values for providerd keys.
 @param keyedValues Dictionary with metadata.
 @param key The unique key.
 */
- (void)setMetadataValues:(NSDictionary *)keyedValues forKey:(NSString *)key;

/*! Removes metadata for key.
 @param key The unique key.
 */
- (void)removeMetadataForKey:(NSString *)key;

#pragma mark - Cleanup

/*! Sets cleanup time interval and schedules cleanup timer with the given timer interal if the cleanup timer is enabled. Default value is 60 seconds.
 */
- (void)setCleanupTimerInterval:(NSTimeInterval)timeInterval;

/*! Enables or disables cleanup timer. Cleanup timer is enabled by default.
 */
- (void)setCleanupTimerEnabled:(BOOL)enabled;

/*! Cleanup disk cache asynchronously.
 */
- (void)cleanupDiskCache;

@end
