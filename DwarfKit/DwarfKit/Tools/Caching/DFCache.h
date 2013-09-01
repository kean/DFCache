//
//  DFImageCaching.h
//  Dwarf
//
//  Created by Alexander Grebenyuk on 7/14/13.
//  Copyright (c) 2013 Alexander Grebenyuk. All rights reserved.
//

#if TARGET_OS_IPHONE
#import "DFImageCaching.h"
#endif

typedef struct {
    /*! Used to calculate cache entries expiration date. Expiration date can be modified at any time for each separate file.
     @discussion Set expiration period to 0 to disable file expiration.
     */
    NSTimeInterval filesExpirationPeriod; // Seconds
    
    /*! Maximum disk cache capacity. Not a strict limit. Disk cache is actually cleared each time application resigns active (for iOS) and any time - (void)cleanupDiskCache gets called.
     */
    unsigned long long diskCacheCapacity; // Bytes
    
    /*! Used to calculate target size by deafult clenaup algorithm.
     */
    CGFloat cleanupTargetSizeRatio;
    
} DFCacheSettings;


#pragma mark - DFCache Metadata -

static NSString * const
DFCacheMetaCreationDateKey = @"_df_creation_date";
static NSString * const
DFCacheMetaAccessDateKey = @"_df_access_date";
static NSString * const
DFCacheMetaExpirationDateKey = @"_df_expiration_date";
static NSString * const
DFCacheMetaFileNameKey = @"_df_file_name";
static NSString * const
DFCacheMetaFileSizeKey = @"_df_file_size"; // Becomes available only after file is written on disk


#pragma mark - DFCache -

/*!
 Efficient memory and disk key-value storage.
 
 Features:
 - General purpose. Stores any Objective-C objects. Built-in support for image caching (<DFImageCaching> implementation) and caching of <NSCodying> objects. 
 - Metadata. Cache entries have associated metadata. You can read/write entry's metadata at any time and even add your custom keys.
 - LRU cleanup. Read more in - (void)cleanupDiskCache discussion.
 - Thread safety. Built on top of GCD. Two internal concurrent queues provide full thread safety and best performance. 
 - Performance. Synchronization based on reader-writer pattern allows all metadata and disk read operation to be concurrent and fast. Image caching performance is fantastic due to libjpeg-turbo which is used under the hood. Disk cache faults are handled instantly without disk I/O.
 */
NS_CLASS_AVAILABLE(10_7, 5_0)
@interface DFCache : NSObject

#if TARGET_OS_IPHONE
<DFImageCaching>
#endif

/*! Init cache with specified name. Name defines paths to cache folders.
 */
- (id)initWithName:(NSString *)name;

@property (nonatomic, strong, readonly) NSString *name;

/*! Settings. For more information DFCacheSettings struct description.
 */
@property (nonatomic) DFCacheSettings settings;

/*! Memory cache implementation 
 */
@property (nonatomic, strong, readonly) NSCache *memoryCache;

#pragma mark - Caching (Read)

/*! Calls completion block on the provided queue with object from disk cache. Memory cache isn't checked.
 @param key The unique key.
 @param queue Queue to execute completion block on. Main queue if NULL.
 @param transform Transformation block that returns object from data.
 @param completion Completion block that gets called on the provided queue.
 */
- (void)objectForKey:(NSString *)key
               queue:(dispatch_queue_t)queue
           transform:(id (^)(NSData *data))transform
          completion:(void (^)(id object))completion;

/*! Returns object from memory cache.
 */
- (id)objectForKey:(NSString *)key;

#pragma mark - Caching (Write)

/*! Stores object into memory cache. Stores object data representation into disk cache if either data or transform parameter is present.
 @param object The object to store into memory cache.
 @param metadata Keyed values to append to default metadata.
 @param key The unique key.
 @param cost The cost with which to associate the object (used by memory cache).
 @param data Data to store into disk cache.
 @param transform Transformation block that returns object data representation.
 */
- (void)storeObject:(id)object
           metadata:(NSDictionary *)metadata
             forKey:(NSString *)key
               cost:(NSUInteger)cost
               data:(NSData *)data
          transform:(NSData *(^)(id object))transform;

- (void)storeObject:(id)object
             forKey:(NSString *)key
               data:(NSData *)data
          transform:(NSData *(^)(id))transform;

/*! Stores object into memory cache.
 @param object The object to store into memory cache.
 @param key The unique key.
 @param cost The cost with which to associate the object. Pass 0 if you don't wan't to specify the cost. Read NSCache setObject:forKey:cost: description to know more.
 */
- (void)storeObject:(id)object forKey:(NSString *)key cost:(NSUInteger)cost;
- (void)storeObject:(id)object forKey:(NSString *)key;

#pragma mark - Metadata

/*! Returns copy of cache entry metadata for specified key.
*/
- (NSDictionary *)metadataForKey:(NSString *)key;

/*! Sets metadata values for specified keys. You can set values for either built-in metadata keys or your custom keys.
 */
- (void)setMetadataValues:(NSDictionary *)keyedValues forKey:(NSString *)key;

#pragma mark - Caching (Remove)

/*! Removes object from both disk and memory cache.
 */
- (void)removeObjectsForKeys:(NSArray *)keys;
- (void)removeObjectForKey:(NSString *)key;
- (void)removeAllObjects;

/*! Options used be removal methods.
 */
typedef NS_OPTIONS(NSUInteger, DFCacheRemoveOptions) {
    DFCacheRemoveFromMemory = (1 << 0),
    DFCacheRemoveFromDisk = (1 << 1)
};

/*! Removes objects from memory and/or disk cache based on options */
- (void)removeObjectsForKeys:(NSArray *)keys options:(DFCacheRemoveOptions)options;
- (void)removeObjectForKey:(NSString *)key options:(DFCacheRemoveOptions)options;
- (void)removeAllObjects:(DFCacheRemoveOptions)options;

#pragma mark - Maintenance

/*! Cleans disk cache.
 @param cleanupBlock Custom cleanup algorithm. If nil uses either custom algorithm set in - (void)setDiskCleanupBlock: or default cleanup algorithm.
 @discussion Default cleaning implementation consists of two passes:
    - First pass. All expired files are removed.
    - Second pass (run only if max disk cache capacity is set to non-zero value). Calculates target size (half of max disk cache capacity). Remaining (after first pass) files are removed according to LRU algorithm until cache size fits target size.
 */
- (void)cleanupDiskCache:(NSArray *(^)(NSDictionary *metatable))cleanupBlock;
- (void)cleanupDiskCache;

/* Algorithm used to define which files should be deleted while cleaning disk. Return array of keys for cache entries that should be deleted.
 */
- (void)setDiskCleanupBlock:(NSArray *(^)(NSDictionary *metatable))cleanupBlock;

/*! Returns current disk cache size. Not a strict value since we don't now file size until it's written to disk.
*/
- (unsigned long long)diskCacheSize;

#pragma mark - <DFImageCaching> -

#if TARGET_OS_IPHONE

/*! Stores image in both memory and disk cache.
 @param image Image to store in memory cache.
 @param imageData Image data to store in disk cache. IF imageData is nil images are compressed and stored in JPEG files.
 @param key The unique key.
 @discussion Method calculates image cost by multiplying it's pixel size and width. You may take advantage of NSCache - (void)setTotalCostLimit: by setting it for - (NSCache)memoryCache property.
 @discussion Use - (void)storeObject:forKey: if you need to store the object in memory cache only.
 */
- (void)storeImage:(UIImage *)image
         imageData:(NSData *)imageData
            forKey:(NSString *)key;

/*! Calls completion block with image from disk cache. Doesn't check memory cache.
 @param key The unique key.
 @param queue Queue that is used to execute completion block on.
 @param completion Completion block that gets called on the main queue (or on your queue if queue parameter isn't NULL).
 */
- (void)imageForKey:(NSString *)key
              queue:(dispatch_queue_t)queue
         completion:(void (^)(UIImage *image))completion;

/*! Returns image from memory cache.
 */
- (UIImage *)imageForKey:(NSString *)key;

#endif

#pragma mark - <NSCoding> -

/*! Stores object in memory cache. Archives object and stores data in disk cache.
 @discussion Use - (void)storeObject:forKey: if you need to store the object only in memory cache.
 */
- (void)storeCodingObject:(id<NSCoding>)object
                 metadata:(NSDictionary *)metadata
                     cost:(NSUInteger)cost
                   forKey:(NSString *)key;

/*! Calls completion block with object from disk cache. Doesn't check memory cache.
 @param key The unique key.
 @param queue Queue that is used to execute completion block on.
 @param completion Completion block that gets called on the main queue (or on your queue if queue parameter isn't NULL).
 @discussion Use - (void)objectForKey method to get object from memory cache.
 */
- (void)codingObjectForKey:(NSString *)key
                     queue:(dispatch_queue_t)queue
                completion:(void (^)(id object))completion;


@end
