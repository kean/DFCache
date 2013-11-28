/*
 The MIT License (MIT)
 
 Copyright (c) 2013 Alexander Grebenyuk (github.com/kean).
 
 Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:
 
 The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.
 
 THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
 */

typedef NSUInteger (^DFCacheCostBlock)(id object);
typedef id (^DFCacheDecodeBlock)(NSData *data);
typedef NSData *(^DFCacheEncodeBlock)(id object);

/* DFCache Features.
 
 - General purpose. Store any Objective-C objects. Built-in support for caching UIImage, <NSCoding> and JSON objects.
 - Metadata. Add custom metadata for any key.
 - LRU cleanup. Read more in - (void)cleanupDisk discussion.
 - Performance. Image caching performance is fantastic due to libjpeg-turbo which is used under the hood.
 */

#pragma mark - DFCache -

/** Efficient memory and file key-value storage.
 */
NS_CLASS_AVAILABLE(10_7, 5_0)
@interface DFCache : NSObject

/** Initializes and returns cache with provided name and memory cache.
 @param name Defines paths to cache folders.
 @param memoryCache Memory cache. Pass nil to disable memory caching.
 */
- (id)initWithName:(NSString *)name memoryCache:(NSCache *)memoryCache;

/** Returns the name of the cache.
 */
@property (nonatomic, readonly) NSString *name;

/*! Returns memory cache or nil if cache was initialized without the memory cache.
 */
@property (nonatomic, readonly) NSCache *memoryCache;

/** Maximum disk cache capacity. If 0 then disk space is unlimited.
 @discussion Not a strict limit. Disk cache is actually cleaned up each time application resigns active (for iOS) and any time - (void)cleanupDisk gets called.
 */
@property (nonatomic) unsigned long long diskCapacity;

/** Remaining disk usage after cleanup. The rate must be in the range of 0.0 to 1.0 where 1.0 represents full disk capacity.
 */
@property (nonatomic) CGFloat cleanupRate;

#pragma mark - Read

/** Reads data from disk.
 @param key The unique key.
 @param completion Completion block.
 */
- (void)cachedDataForKey:(NSString *)key completion:(void (^)(NSData *data))completion;

/** Reads data from disk synchronously.
@param key The unique key.
*/
- (NSData *)cachedDataForKey:(NSString *)key;
 
/** Reads object from disk.
 @param key The unique key.
 @param decode Decoding block returning object from data.
 @param cost Cost block returning cost for memory cache.
 @param completion Completion block.
 */
- (void)cachedObjectForKey:(NSString *)key
                    decode:(DFCacheDecodeBlock)decode
                      cost:(DFCacheCostBlock)cost
                completion:(void (^)(id object))completion;

/** Returns object from disk synchorounsly.
 @param key The unique key.
 @param decode Decoding block returning object from data.
 @param cost Cost block returning cost for memory cache.
 */
- (id)cachedObjectForKey:(NSString *)key
                  decode:(DFCacheDecodeBlock)decode
                    cost:(DFCacheCostBlock)cost;

/** Checks if object data representation is stored into disk cache.
 */
- (BOOL)containsDataForKey:(NSString *)key;

#pragma mark - Read (Multiple Keys)

/** Reads objects for provided keys.
 @param keys Array of unique keys.
 @param decode Decoding block returning object from data.
 @param cost Cost block returning cost for memory cache.
 @param completion Completion block.
 */
- (void)cachedObjectsForKeys:(NSArray *)keys
                      decode:(DFCacheDecodeBlock)decode
                        cost:(DFCacheCostBlock)cost
                  completion:(void (^)(NSDictionary *objects))completion;

/*! Reads first found object for provided keys.
 @param key The unique key.
 @param decode Decoding block returning object from data.
 @param cost Cost block returning cost for memory cache.
 @param completion Completion block.
 */
- (void)cachedObjectForKeys:(NSArray *)keys
                     decode:(DFCacheDecodeBlock)decode
                       cost:(DFCacheCostBlock)cost
                 completion:(void (^)(id object, NSString *key))completion;

#pragma mark - Write

/** Stores data into disk cache.
 @param data Data to store into disk cache.
 @param key The unique key.
 */
- (void)storeData:(NSData *)data forKey:(NSString *)key;

/** Stores object into memory cache. Stores data into disk cache.
 @param object The object to store into memory cache.
 @param key The unique key.
 @param cost The cost with which to associate the object (used by memory cache).
 @param data Data to store into disk cache.
 */
- (void)storeObject:(id)object
             forKey:(NSString *)key
               cost:(NSUInteger)cost
               data:(NSData *)data;

/** Stores object into memory cache. Stores data representation provided by the transformation block into disk cache.
 @param object The object to store into memory cache.
 @param key The unique key.
 @param cost The cost with which to associate the object (used by memory cache).
 @param encode Encoder block returning object's data representation.
 */
- (void)storeObject:(id)object
             forKey:(NSString *)key
               cost:(NSUInteger)cost
             encode:(DFCacheEncodeBlock)encode;

#pragma mark - Metadata

/** Returns copy of metadata for provided key.
 @param key The unique key.
 @return Copy of metadata for key.
 */
- (NSDictionary *)metadataForKey:(NSString *)key;

/** Reads metadata for provided key. Calls completion block with copy of metadata.
 @param key The unique key.
 @param completion Completion block.
 */
- (void)metadataForKey:(NSString *)key completion:(void (^)(NSDictionary *metadata))completion;

/** Sets metadata for provided key.
 @param metadata Dictionary with metadata.
 @param key The unique key.
 */
- (void)setMetadata:(NSDictionary *)metadata forKey:(NSString *)key;

/** Sets metadata values for providerd keys.
 @param keyedValues Dictionary with metadata.
 @param key The unique key.
 */
- (void)setMetadataValues:(NSDictionary *)keyedValues forKey:(NSString *)key;

/** Removes metadata for key.
 @param key The unique key.
 */
- (void)removeMetadataForKey:(NSString *)key;

#pragma mark - Remove

/** Removes object from both disk and memory cache.
 */
- (void)removeObjectsForKeys:(NSArray *)keys;
- (void)removeObjectForKey:(NSString *)key;
- (void)removeAllObjects;

#pragma mark - Maintenance

/** Cleans up disk by removing entries by LRU algorithm.
 @discussion Cleanup algorithm runs only if max disk cache capacity is set to non-zero value. Calculates target size by multiplying disk capacity and cleanup rate. Files are removed according to LRU algorithm until cache size fits target size.
 */
- (void)cleanupDisk;

/** Returns the current size of the receiver’s on-disk cache, in bytes.
 @warning Very expensive. Should be run rarely.
 */
- (unsigned long long)currentDiskUsage;

@end


#pragma mark - DFCache (Blocks) -

@interface DFCache (Blocks)

#if TARGET_OS_IPHONE
@property (nonatomic, readonly) DFCacheDecodeBlock blockUIImageDecode;
@property (nonatomic, readonly) DFCacheEncodeBlock blockUIImageEncode;
@property (nonatomic, readonly) DFCacheCostBlock blockUIImageCost;
#endif

@property (nonatomic, readonly) DFCacheDecodeBlock blockJSONDecode;
@property (nonatomic, readonly) DFCacheEncodeBlock blockJSONEncode;

@end


#pragma mark - DFCache (UIImage) -

#if TARGET_OS_IPHONE
@interface DFCache (UIImage)

- (void)storeImage:(UIImage *)image imageData:(NSData *)data forKey:(NSString *)key;
- (void)cachedImageForKey:(NSString *)key completion:(void (^)(UIImage *image))completion;
- (void)cachedImageForKeys:(NSArray *)keys
                completion:(void (^)(UIImage *image, NSString *key))completion;

@end
#endif


#pragma mark - DFCache (Shared) -

@interface DFCache (Shared)

+ (instancetype)imageCache;

@end
