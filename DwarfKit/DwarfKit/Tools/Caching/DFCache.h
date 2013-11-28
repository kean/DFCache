/*
 The MIT License (MIT)
 
 Copyright (c) 2013 Alexander Grebenyuk (github.com/kean).
 
 Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:
 
 The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.
 
 THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
 */

#import "DFStorage.h"

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

/** Efficient memory and disk cache. 
 @discussion DFCache is not just a convenience interface for DFStorage and NSCache. It also extends DFStorage and NSCache functionality is several ways, like associating metadata with objects.
 */
NS_CLASS_AVAILABLE(10_7, 5_0)
@interface DFCache : NSObject

/** Initializes and returns cache with provided disk storage and memory cache.
 @param diskStorage Disk storage. Must not be nil.
 @param memoryCache Memory cache. Pass nil to disable memory caching.
 */
- (id)initWithDiskCache:(DFStorage *)diskCache memoryCache:(NSCache *)memoryCache;

/** Convenience method. Initializes and returns cache with provided name and memory cache.
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
@property (nonatomic, readonly) DFStorage *diskCache;

#pragma mark - Read
 
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

#pragma mark - Write

/** Stores object into memory cache. Stores data into disk cache.
 @param object The object to store into memory cache.
 @param key The unique key.
 @param cost The cost with which to associate the object (used by memory cache).
 @param data Data to store into disk cache.
 @warning Method doesn's remove metadata associated with provided key.
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
 @warning Method doesn's remove metadata associated with provided key.
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

@end


#pragma mark - DFCache (Blocks) -

@interface DFCache (Blocks)

#if TARGET_OS_IPHONE
@property (nonatomic, readonly) DFCacheEncodeBlock blockUIImageEncode;
@property (nonatomic, readonly) DFCacheDecodeBlock blockUIImageDecode;
@property (nonatomic, readonly) DFCacheCostBlock blockUIImageCost;
#endif

@property (nonatomic, readonly) DFCacheEncodeBlock blockJSONEncode;
@property (nonatomic, readonly) DFCacheDecodeBlock blockJSONDecode;

@property (nonatomic, readonly) DFCacheEncodeBlock blockNSCodingEncode;
@property (nonatomic, readonly) DFCacheDecodeBlock blockNSCodingDecode;

@end


#pragma mark - DFCache (UIImage) -

#if TARGET_OS_IPHONE
@interface DFCache (UIImage)

- (void)storeImage:(UIImage *)image imageData:(NSData *)data forKey:(NSString *)key;
- (void)cachedImageForKey:(NSString *)key completion:(void (^)(UIImage *image))completion;

@end
#endif


#pragma mark - DFCache (Shared) -

@interface DFCache (Shared)

+ (instancetype)imageCache;

@end
