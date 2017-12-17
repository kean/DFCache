// The MIT License (MIT)
//
// Copyright (c) 2015 Alexander Grebenyuk (github.com/kean).

#import <Foundation/Foundation.h>
#import "DFDiskCache.h"
#import "DFValueTransformer.h"
#import "DFValueTransformerFactory.h"
#import "DFCacheImageDecoder.h"
#import "NSURL+DFExtendedFileAttributes.h"

NS_ASSUME_NONNULL_BEGIN

/*! Extended attribute name used to store metadata (see NSURL+DFExtendedFileAttributes).
 */
extern NSString *const DFCacheAttributeMetadataKey;


/* DFCache key features:
 
 - Concise, extensible and well-documented API.
 - Thoroughly tested. Written for and used heavily in the iOS application with more than half a million active users.
 - LRU cleanup (discards least recently used items first).
 - Metadata implemented on top on UNIX extended file attributes.
 - First class UIImage support including background image decompression.
 - Builtin support for objects conforming to <NSCoding> protocol. Can be extended to support more protocols and classes.
 - Batch methods to retrieve cached entries.
 */

/*! Asynchronous composite in-memory and on-disk cache with LRU cleanup.
 @discussion Uses NSCache for in-memory caching and DFDiskCache for on-disk caching. Provides API for associating metadata with cache entries.
 @note Encoding and decoding is implemented using id<DFValueTransforming> protocol. DFCache has several builtin value transformers that support object conforming to <NSCoding> protocol and images (UIImage). Use value transformer factory (id<DFValueTransformerFactory>) to extend cache functionality.
 @note All disk IO operations (including operations that associate metadata with cache entries) are run on a serial dispatch queue. If you store the object using DFCache asynchronous API and then immediately retrieve it you are guaranteed to get the object back.
 @note Default disk capacity is 100 Mb. Disk cleanup is implemented using LRU algorithm, the least recently used items are discarded first. Disk cleanup is automatically scheduled to run repeatedly.
 @note NSCache auto-removal policies have change with the release of iOS 7.0. Make sure that you use reasonable total cost limit or count limit. Or else NSCache won't be able to evict memory properly. Typically, the obvious cost is the size of the object in bytes. Keep in mind that DFCache automatically removes all object from memory cache on memory warning for you.
 */
@interface DFCache : NSObject

/*! Initializes and returns cache with provided disk and memory cache.
 @param diskCache Disk cache. Pass nil to disable on-disk caching.
 @param memoryCache Memory cache. Pass nil to disable in-memory caching.
 */
- (instancetype)initWithDiskCache:(nullable DFDiskCache *)diskCache memoryCache:(nullable NSCache *)memoryCache NS_DESIGNATED_INITIALIZER;

/*! Initializes cache by creating DFDiskCache instance with a given name and calling designated initializer.
 @param name Name used to initialize disk cache. Raises NSInvalidArgumentException if name length is 0.
 @param memoryCache Memory cache. Pass nil to disable in-memory cache.
 */
- (instancetype)initWithName:(NSString *)name memoryCache:(nullable NSCache *)memoryCache;

/*! Initializes cache by creating DFDiskCache instance with a given name and NSCache instance and calling designated initializer.
 @param name Name used to initialize disk cache. Raises NSInvalidArgumentException if name length is 0.
 */
- (instancetype)initWithName:(NSString *)name;

/*! Unavailable initializer, please use designated initializer.
 */
- (instancetype)init NS_UNAVAILABLE;

/*! The transformer factory used by cache. Cache is initialized with a default value transformer factory. For more info see DFValueTransformerFactory declaration.
 */
@property (nonatomic) id<DFValueTransformerFactory> valueTransfomerFactory;

/*! Returns disk cache used by receiver.
 */
@property (nullable, nonatomic, readonly) DFDiskCache *diskCache;

/*! Returns memory cache used by receiver. Memory cache might be nil.
 */
@property (nullable, nonatomic, readonly) NSCache *memoryCache;

#pragma mark - Read

/*! Reads object from either in-memory or on-disk cache. Refreshes object in memory cache it it was retrieved from disk. Uses value transformer provided by value transformer factory.
 @param key The unique key.
 @param completion Completion block.
 */
- (void)cachedObjectForKey:(NSString *)key completion:(void (^__nullable)(id __nullable object))completion;

/*! Returns object from either in-memory or on-disk cache. Refreshes object in memory cache it it was retrieved from disk. Uses value transformer provided by value transformer factory.
 @param key The unique key.
 */
- (nullable id)cachedObjectForKey:(NSString *)key;

#pragma mark - Write

/*! Stores object into memory cache. Retrieves value transformer from factory, encodes object and stores data into disk cache. Value transformer gets associated with data.
 @param object The object to store into memory cache.
 @param key The unique key.
 */
- (void)storeObject:(id)object forKey:(NSString *)key;

/*! Stores object into memory cache. Stores data into disk cache. Retrieves value transformer from factory and  associates it with data.
 @param object The object to store into memory cache.
 @param key The unique key.
 @param data Data to store into disk cache.
 */
- (void)storeObject:(id)object forKey:(NSString *)key data:(nullable NSData *)data;

/*! Stores object into memory cache. Retrieves value transformer from factory and uses it to calculate object cost.
 @param object The object to store into memory cache.
 */
- (void)setObject:(id)object forKey:(NSString *)key;

#pragma mark - Remove

/*! Removes objects from both disk and memory cache. Metadata is also removed.
 @param keys Array of strings.
 */
- (void)removeObjectsForKeys:(NSArray *)keys;

/*! Removes object from both disk and memory cache. Metadata is also removed.
 @param key The unique key.
 */
- (void)removeObjectForKey:(NSString *)key;

/*! Removes all objects both disk and memory cache. Metadata is also removed.
 */
- (void)removeAllObjects;

#pragma mark - Metadata

/*! Returns copy of metadata for provided key.
 @param key The unique key.
 @return Copy of metadata for key.
 */
- (nullable NSDictionary *)metadataForKey:(NSString *)key;

/*! Sets metadata for provided key. 
 @warning Method will have no effect if there is no entry under the given key.
 @param metadata Dictionary with metadata.
 @param key The unique key.
 */
- (void)setMetadata:(NSDictionary *)metadata forKey:(NSString *)key;

/*! Sets metadata values for provided keys.
 @warning Method will have no effect if there is no entry under the given key.
 @param keyedValues Dictionary with metadata.
 @param key The unique key.
 */
- (void)setMetadataValues:(NSDictionary *)keyedValues forKey:(NSString *)key;

/*! Removes metadata for key.
 @param key The unique key.
 */
- (void)removeMetadataForKey:(NSString *)key;

#pragma mark - Cleanup

/*! Sets cleanup time interval and schedules cleanup timer with the given time interval. 
 @discussion Cleanup timer is scheduled only if automatic cleanup is enabled. Default value is 60 seconds.
 */
- (void)setCleanupTimerInterval:(NSTimeInterval)timeInterval;

/*! Enables or disables cleanup timer. Cleanup timer is enabled by default.
 */
- (void)setCleanupTimerEnabled:(BOOL)enabled;

/*! Cleanup disk cache asynchronously. For more info see DFDiskCache - (void)cleanup.
 */
- (void)cleanupDiskCache;

#pragma mark - Data

/*! Retrieves data from disk cache.
 @param key The unique key.
 @param completion Completion block.
 */
- (void)cachedDataForKey:(NSString *)key completion:(void (^__nullable)(NSData *__nullable data))completion;

/*! Reads data from disk cache synchronously.
 @param key The unique key.
 */
- (nullable NSData *)cachedDataForKey:(NSString *)key;

/*! Stores data into disk cache asynchronously.
 @param data Data to be stored into disk cache.
 @param key The unique key.
 */
- (void)storeData:(NSData *)data forKey:(NSString *)key;

@end


#if TARGET_OS_IOS || TARGET_OS_TV
@interface DFCache (UIImage)

- (void)setAllowsImageDecompression:(BOOL)allowsImageDecompression;

@end
#endif


@interface DFCache (DFCacheExtended)

/*! Retrieves batch of NSData instances for the given keys.
 @param keys Array of the unique keys.
 @param completion Completion block. Batch dictionary contains key:data pairs.
 */
- (void)batchCachedDataForKeys:(NSArray *)keys completion:(void (^__nullable)(NSDictionary *__nullable batch))completion;

/*! Returns dictionary with NSData instances that correspond to the given keys.
 @param keys Array of the unique keys.
 @return NSDictionary instance with key:data pairs.
 */
- (nullable NSDictionary *)batchCachedDataForKeys:(NSArray *)keys;

/*! Retrieves batch of objects that correspond to the given keys.
 @param keys Array of the unique keys.
 @param completion Completion block. Batch dictionary contains key : object pairs retrieved from receiver.
 */
- (void)batchCachedObjectsForKeys:(NSArray *)keys completion:(void (^__nullable)(NSDictionary *__nullable batch))completion;

/*! Returns batch of objects that correspond to the given keys.
 @param keys Array of the unique keys.
 @return NSDictionary instance with key:data pairs.
 */
- (nullable NSDictionary *)batchCachedObjectsForKeys:(NSArray *)keys;

/*! Retrieves first found object for the given keys.
 @param keys An array of unique keys.
 @param completion Completion block.
 */
- (void)firstCachedObjectForKeys:(NSArray *)keys completion:(void (^__nullable)(id __nullable object, NSString *__nullable key))completion;

@end

NS_ASSUME_NONNULL_END
