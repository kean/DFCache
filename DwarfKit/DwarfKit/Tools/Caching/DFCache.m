/*
 The MIT License (MIT)
 
 Copyright (c) 2013 Alexander Grebenyuk (github.com/kean).
 
 Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:
 
 The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.
 
 THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
 */

#import "DFCache.h"
#import "DFCrypto.h"
#import "DFOptions.h"
#import "DFObjCExtenstions.h"

#import "dwarf_private.h"

#if TARGET_OS_IPHONE
#import "DFImageProcessing.h"
#endif


#pragma mark - _DFCachePaths -

@interface _DFCachePaths : NSObject

@property (nonatomic) NSString *root;
@property (nonatomic) NSString *entries;
@property (nonatomic) NSString *metadata;

- (id)initWithName:(NSString *)name;
- (NSString *)entryPathWithName:(NSString *)name;
- (NSString *)metadataPathWithName:(NSString *)name;

@end

@implementation _DFCachePaths

- (id)initWithName:(NSString *)name {
   if (self = [super init]) {
      NSArray *paths = NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES);
      _root = [paths[0] stringByAppendingPathComponent:name];
      _entries = [_root stringByAppendingPathComponent:@"entries"];
      _metadata = [_root stringByAppendingPathComponent:@"metadata"];
   }
   return self;
}

- (NSString *)entryPathWithName:(NSString *)name {
   return name ? [_entries stringByAppendingPathComponent:name] : nil;
}

- (NSString *)metadataPathWithName:(NSString *)name {
   return name ? [_metadata stringByAppendingPathComponent:name] : nil;
}

@end


#pragma mark - DFCache -

@implementation DFCache {
   _DFCachePaths *_paths;
   dispatch_queue_t _ioQueue;
   NSCache *_memorizedHashes;
}

- (void)dealloc {
   [[NSNotificationCenter defaultCenter] removeObserver:self];
   DWARF_DISPATCH_RELEASE(_ioQueue);
}

- (id)initWithName:(NSString *)name memoryCache:(NSCache *)memoryCache {
   if (self = [super init]) {
      if (!name) {
         return nil;
      }
      _diskCapacity = 1024 * 1024 * 100; // 100 Mb
      _cleanupRate = 0.5;
      _memoryCache.totalCostLimit = 1024 * 1024 * 15; // 15 Mb
      
      _ioQueue = dispatch_queue_create("dwarf.cache.ioqueue", DISPATCH_QUEUE_SERIAL);
      
      _memorizedHashes = [NSCache new];
      _memorizedHashes.countLimit = 150;
      
      _memoryCache = memoryCache;
      _memoryCache.name = name;
      _name = name;
      
      _paths = [[_DFCachePaths alloc] initWithName:name];
      
      [self _addNotificationObservers];
   }
   return self;
}

- (id)init {
   return [self initWithName:@"_df_cache_default" memoryCache:[NSCache new]];
}

- (void)_addNotificationObservers {
   NSNotificationCenter *center = [NSNotificationCenter defaultCenter];
   [center addObserver:self selector:@selector(applicationWillResignActive:) name:DFApplicationWillResignActiveNotification object:nil];
#if TARGET_OS_IPHONE
   [center addObserver:self selector:@selector(applicationDidReceiveMemoryWarning:) name:UIApplicationDidReceiveMemoryWarningNotification object:nil];
#endif
}

#pragma mark - Read

- (void)cachedDataForKey:(NSString *)key completion:(void (^)(NSData *))completion {
   if (!completion) {
      return;
   }
   if (!key) {
      _dwarf_callback(completion, nil);
      return;
   }
   dispatch_async(_ioQueue, ^{
      NSData *data = [self _dataForKey:key];
      _dwarf_callback(completion, data);
   });
}

- (void)cachedObjectForKey:(NSString *)key decode:(DFCacheDecodeBlock)decode cost:(DFCacheCostBlock)cost completion:(void (^)(id))completion {
   if (!completion) {
      return;
   }
   if (!key) {
      _dwarf_callback(completion, nil);
      return;
   }
   dispatch_async(_ioQueue, ^{
      id object = [_memoryCache objectForKey:key];
      if (object) {
         _dwarf_callback(completion, object);
         return;
      }
      NSData *data = [self _dataForKey:key];
      if (!data) {
         _dwarf_callback(completion, nil);
         return;
      }
      dispatch_async([self _processingQueue], ^{
         id object = decode(data);
         if (object) {
            [self _touchObject:object forKey:key cost:cost];
            [self _touchFileForKey:key];
         }
         _dwarf_callback(completion, object);
         
      });
   });
}

- (id)cachedObjectForKey:(NSString *)key decode:(DFCacheDecodeBlock)decode cost:(DFCacheCostBlock)cost {
   if (!key || !decode) {
      return nil;
   }
   id object = [self cachedObjectForKey:key];
   if (!object) {
      __block NSData *data;
      dispatch_sync(_ioQueue, ^{
         data = [self _dataForKey:key];
      });
      object = decode(data);
      if (object) {
         [self _touchObject:object forKey:key cost:cost];
         [self _touchFileForKey:key];
      }
   }
   return object;
}

- (dispatch_queue_t)_processingQueue {
   return dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0);
}

- (void)_touchFileForKey:(NSString *)key {
   NSString *hash = [self _hashWithKey:key];
   NSString *filepath = [_paths entryPathWithName:hash];
   NSURL *url = [NSURL fileURLWithPath:filepath];
   [url setResourceValue:[NSDate date] forKey:NSURLAttributeModificationDateKey error:nil];
}

- (void)_touchObject:(id)object forKey:(NSString *)key cost:(DFCacheCostBlock)cost {
   if (!object || !key) {
      return;
   }
   NSUInteger objectCost = cost ? cost(object) : 0;
   [_memoryCache setObject:object forKey:key cost:objectCost];
}

- (id)cachedObjectForKey:(NSString *)key {
   return key ? [_memoryCache objectForKey:key] : nil;
}

- (BOOL)containsObjectForKey:(NSString *)key {
   if (!key) {
      return NO;
   }
   if ([_memoryCache objectForKey:key]) {
      return YES;
   }
   NSString *hash = [self _hashWithKey:key];
   NSString *filepath = [_paths entryPathWithName:hash];
   return [[NSFileManager defaultManager] fileExistsAtPath:filepath];
}

#pragma mark - Read (Multiple Keys)

- (void)cachedObjectForKeys:(NSArray *)keys decode:(DFCacheDecodeBlock)decode cost:(DFCacheCostBlock)cost completion:(void (^)(id, NSString *))completion {
   if (!completion) {
      return;
   }
   if (!keys.count) {
      dispatch_async(dispatch_get_main_queue(), ^{
         completion(nil, nil);
      });
      return;
   }
   dispatch_async(_ioQueue, ^{
      id foundObject;
      NSString *foundKey;
      for (NSString *key in keys) {
         id object = [_memoryCache objectForKey:key];
         if (object) {
            foundObject = object;
            foundKey = key;
            break;
         }
         NSData *data = [self _dataForKey:key];
         if (!data) {
            continue;
         }
         object = decode(data);
         if (object) {
            foundObject = object;
            foundKey = key;
            [self _touchObject:object forKey:key cost:cost];
            [self _touchFileForKey:key];
            break;
         }
      }
      dispatch_async(dispatch_get_main_queue(), ^{
         completion(foundObject, foundKey);
      });
   });
}

- (void)cachedObjectsForKeys:(NSArray *)keys decode:(DFCacheDecodeBlock)decode cost:(DFCacheCostBlock)cost completion:(void (^)(NSDictionary *))completion {
   if (!completion) {
      return;
   }
   if (!keys.count) {
      _dwarf_callback(completion, nil);
      return;
   }
   dispatch_async(_ioQueue, ^{
      NSMutableDictionary *objects = [NSMutableDictionary new];
      for (NSString *key in keys) {
         id object = [_memoryCache objectForKey:key];
         if (object) {
            objects[key] = object;
            continue;
         }
         NSData *data = [self _dataForKey:key];
         object = decode(data);
         if (object) {
            [self _touchObject:object forKey:key cost:cost];
            [self _touchFileForKey:key];
            objects[key] = object;
         }
      }
      _dwarf_callback(completion, objects);
   });
}

#pragma mark - Write

- (void)storeData:(NSData *)data forKey:(NSString *)key {
   if (!data || !key) {
      return;
   }
   dispatch_async(_ioQueue, ^{
      [self _storeData:data forKey:key];
   });
}

- (void)_storeData:(NSData *)data forKey:(NSString *)key {
   [self _createCacheDirectories];
   NSString *hash = [self _hashWithKey:key];
   NSString *filepath = [_paths entryPathWithName:hash];
   NSFileManager *manager = [NSFileManager defaultManager];
   [manager createFileAtPath:filepath contents:data attributes:nil];
}

- (void)storeObject:(id)object
             forKey:(NSString *)key
               cost:(NSUInteger)cost
             encode:(DFCacheEncodeBlock)encode {
   [self _storeObject:object forKey:key cost:cost data:nil encode:encode];
}

- (void)storeObject:(id)object
             forKey:(NSString *)key
               cost:(NSUInteger)cost
               data:(NSData *)data {
   [self _storeObject:object forKey:key cost:cost data:data encode:nil];
}

- (void)_storeObject:(id)object
              forKey:(NSString *)key
                cost:(NSUInteger)cost
                data:(NSData *)data
              encode:(DFCacheEncodeBlock)encode {
   if (!object || !key) {
      return;
   }
   [_memoryCache setObject:object forKey:key cost:cost];
   if (!data && !encode) {
      return;
   }
   dispatch_async(_ioQueue, ^{
      NSData *objData = data ? data : encode(object);
      [self _storeData:objData forKey:key];
      [self _removeMetadataForKey:key];
   });
}

- (void)storeObject:(id)object forKey:(NSString *)key cost:(NSUInteger)cost {
   if (!object || !key) {
      return;
   }
   [_memoryCache setObject:object forKey:key cost:cost];
}

#pragma mark - Metadata

- (NSDictionary *)metadataForKey:(NSString *)key {
   if (!key) {
      return nil;
   }
   __block NSDictionary *metadata;
   dispatch_sync(_ioQueue, ^{
      metadata = [self _metadataForKey:key];
   });
   return [metadata copy];
}

- (void)metadataForKey:(NSString *)key completion:(void (^)(NSDictionary *))completion {
   if (!completion) {
      return;
   }
   if (!key) {
      _dwarf_callback(completion, nil);
      return;
   }
   dispatch_async(_ioQueue, ^{
      NSDictionary *metadata = [self _metadataForKey:key];
      _dwarf_callback(completion, [metadata copy]);
   });
}

- (void)setMetadata:(NSDictionary *)metadata forKey:(NSString *)key {
   if (!metadata || !key) {
      return;
   }
   dispatch_sync(_ioQueue, ^{
      [self _setMetadata:metadata forKey:key];
   });
}

- (void)setMetadataValues:(NSDictionary *)keyedValues forKey:(NSString *)key {
   if (!keyedValues || !key) {
      return;
   }
   dispatch_sync(_ioQueue, ^{
      NSMutableDictionary *metadata = [[NSMutableDictionary alloc] initWithDictionary:[self _metadataForKey:key]];
      [metadata addEntriesFromDictionary:keyedValues];
      [self _setMetadata:metadata forKey:key];
   });
}

- (NSDictionary *)_metadataForKey:(NSString *)key {
   NSString *hash = [self _hashWithKey:key];
   NSString *filepath = [_paths metadataPathWithName:hash];
   return [NSDictionary dictionaryWithContentsOfFile:filepath];
}

- (void)_setMetadata:(NSDictionary *)metadata forKey:(NSString *)key {
   NSString *hash = [self _hashWithKey:key];
   NSString *filepath = [_paths metadataPathWithName:hash];
   [metadata writeToFile:filepath atomically:YES];
}

- (void)removeMetadataForKey:(NSString *)key {
   if (!key) {
      return;
   }
   dispatch_async(_ioQueue, ^{
      [self _removeMetadataForKey:key];
   });
}

- (void)_removeMetadataForKey:(NSString *)key {
   NSString *hash = [self _hashWithKey:key];
   NSString *filepath = [_paths metadataPathWithName:hash];
   [[NSFileManager defaultManager] removeItemAtPath:filepath error:nil];
}

#pragma mark - Remove

- (void)removeObjectsForKeys:(NSArray *)keys options:(DFCacheRemoveOptions)options {
   if (!keys) {
      return;
   }
   if (DF_OPTIONS_IS_ENABLED(options, DFCacheRemoveFromMemory)) {
      for (NSString *key in keys) {
         [_memoryCache removeObjectForKey:key];
      }
   }
   if (DF_OPTIONS_IS_ENABLED(options, DFCacheRemoveFromDisk)) {
      dispatch_async(_ioQueue, ^{
         [self _removeObjectsForKeys:keys];
      });
   }
}

- (void)_removeObjectsForKeys:(NSArray *)keys {
   if (!keys.count) {
      return;
   }
   NSFileManager *manager = [NSFileManager defaultManager];
   for (NSString *key in keys) {
      NSString *hash = [self _hashWithKey:key];
      NSString *filepath = [_paths entryPathWithName:hash];
      [manager removeItemAtPath:filepath error:nil];
      NSString *metadataPath = [_paths metadataPathWithName:hash];
      [manager removeItemAtPath:metadataPath error:nil];
   }
}

- (void)removeObjectsForKeys:(NSArray *)keys {
   [self removeObjectsForKeys:keys options:(DFCacheRemoveFromDisk | DFCacheRemoveFromMemory)];
}

- (void)removeObjectForKey:(NSString *)key options:(DFCacheRemoveOptions)options {
   if (key) {
      [self removeObjectsForKeys:@[key] options:options];
   }
}

- (void)removeObjectForKey:(NSString *)key {
   [self removeObjectForKey:key options:(DFCacheRemoveFromDisk | DFCacheRemoveFromMemory)];
}

- (void)removeAllObjects:(DFCacheRemoveOptions)options {
   if (DF_OPTIONS_IS_ENABLED(options, DFCacheRemoveFromMemory)) {
      [_memoryCache removeAllObjects];
   }
   if (DF_OPTIONS_IS_ENABLED(options, DFCacheRemoveFromDisk)) {
      dispatch_async(_ioQueue, ^{
         NSFileManager *manager = [NSFileManager defaultManager];
         [manager removeItemAtPath:_paths.entries error:nil];
         [manager removeItemAtPath:_paths.metadata error:nil];
      });
   }
}

- (void)removeAllObjects {
   [self removeAllObjects:(DFCacheRemoveFromDisk | DFCacheRemoveFromMemory)];
}

#pragma mark - Maintenance

- (void)cleanupDisk {
   if (_diskCapacity == 0) {
      return;
   }
   dispatch_async(_ioQueue, ^{
      [self _cleanupDisk];
   });
}

- (void)_cleanupDisk {
   NSFileManager *manager = [NSFileManager defaultManager];
   NSURL *entriesURL = [NSURL fileURLWithPath:_paths.entries isDirectory:YES];
   NSArray *resourceKeys = @[ NSURLIsDirectoryKey,
                              NSURLContentModificationDateKey,
                              NSURLFileAllocatedSizeKey ];
   NSDirectoryEnumerator *fileEnumerator =
   [manager enumeratorAtURL:entriesURL
 includingPropertiesForKeys:resourceKeys
                    options:NSDirectoryEnumerationSkipsHiddenFiles
               errorHandler:NULL];
   
   NSMutableDictionary *files = [NSMutableDictionary dictionary];
   _dwarf_bytes currentSize = 0;
   for (NSURL *fileURL in fileEnumerator) {
      NSDictionary *resourceValues = [fileURL resourceValuesForKeys:resourceKeys error:NULL];
      if ([resourceValues[NSURLIsDirectoryKey] boolValue]) {
         continue;
      }
      NSNumber *fileSize = resourceValues[NSURLFileAllocatedSizeKey];
      currentSize += [fileSize unsignedLongLongValue];
      [files setObject:resourceValues forKey:fileURL];
   }
   if (currentSize > _diskCapacity) {
      const _dwarf_bytes desiredSize = _diskCapacity * _cleanupRate;
      NSArray *sortedFiles =
      [files keysSortedByValueWithOptions:NSSortConcurrent usingComparator:^NSComparisonResult(id obj1, id obj2) {
         return [obj1[NSURLContentModificationDateKey] compare:
                 obj2[NSURLContentModificationDateKey]];
      }];
      for (NSURL *fileURL in sortedFiles) {
         if ([manager removeItemAtURL:fileURL error:nil]) {
            NSString *filename = [fileURL lastPathComponent];
            NSString *metadataPath = [_paths metadataPathWithName:filename];
            [manager removeItemAtPath:metadataPath error:nil];
            NSDictionary *resourceValues = files[fileURL];
            NSNumber *fileSize = resourceValues[NSURLFileAllocatedSizeKey];
            currentSize -= [fileSize unsignedLongLongValue];
            if (currentSize < desiredSize) {
               break;
            }
         }
      }
   }
}

- (_dwarf_bytes)currentDiskUsage {
   __block _dwarf_bytes size = 0;
   dispatch_sync(_ioQueue, ^{
      NSFileManager *manager = [NSFileManager defaultManager];
      NSURL *entriesURL = [NSURL fileURLWithPath:_paths.entries isDirectory:YES];
      NSArray *resourceKeys = @[ NSURLIsDirectoryKey,
                                 NSURLFileAllocatedSizeKey ];
      NSDirectoryEnumerator *fileEnumerator =
      [manager enumeratorAtURL:entriesURL
    includingPropertiesForKeys:resourceKeys
                       options:NSDirectoryEnumerationSkipsHiddenFiles
                  errorHandler:NULL];
      for (NSURL *fileURL in fileEnumerator) {
         NSDictionary *resourceValues = [fileURL resourceValuesForKeys:resourceKeys error:NULL];
         if ([resourceValues[NSURLIsDirectoryKey] boolValue]) {
            continue;
         }
         size += [resourceValues[NSURLFileAllocatedSizeKey] unsignedLongLongValue];
      }
   });
   return size;
}

#pragma mark - Private

- (NSString *)_hashWithKey:(NSString *)key {
   NSString *hash = [_memorizedHashes objectForKey:key];
   if (!hash) {
      hash = [DFCrypto MD5FromString:key];
      [_memorizedHashes setObject:hash forKey:key];
   }
   return hash;
}

- (void)_createCacheDirectories {
   [self _createDirectoryAtPath:_paths.root];
   [self _createDirectoryAtPath:_paths.entries];
   [self _createDirectoryAtPath:_paths.metadata];
}

- (void)_createDirectoryAtPath:(NSString *)path {
   NSFileManager *manager = [NSFileManager defaultManager];
   if (![manager fileExistsAtPath:path]) {
      [manager createDirectoryAtPath:path withIntermediateDirectories:YES attributes:nil error:NULL];
   }
}

- (NSData *)_dataForKey:(NSString *)key {
   NSString *hash = [self _hashWithKey:key];
   NSString *filepath = [_paths entryPathWithName:hash];
   return [NSData dataWithContentsOfFile:filepath options:NSDataReadingUncached error:nil];
}

#pragma mark - Application Notifications

- (void)applicationWillResignActive:(NSNotification *)notification {
   [self cleanupDisk];
}

- (void)applicationDidReceiveMemoryWarning:(NSNotification *)notification {
   [_memoryCache removeAllObjects];
   [_memorizedHashes removeAllObjects];
}

@end


#pragma mark - DFCache (Blocks) -

@implementation DFCache (Blocks)

- (DFCacheCostBlock)blockUIImageCost {
   return ^NSUInteger(id object){
      UIImage *image = safe_cast(UIImage, object);
      if (image) {
         return CGImageGetWidth(image.CGImage) * CGImageGetHeight(image.CGImage) * 4;
      }
      return 0;
   };
}

- (DFCacheEncodeBlock)blockUIImageEncode {
   return ^NSData *(UIImage *image){
      return UIImageJPEGRepresentation(image, 1.0);
   };
}

- (DFCacheDecodeBlock)blockUIImageDecode {
   return ^UIImage *(NSData *data) {
      return [DFImageProcessing decompressedImageWithData:data];
   };
}

- (DFCacheEncodeBlock)blockJSONEncode {
   return ^NSData *(id JSON){
      return [NSJSONSerialization dataWithJSONObject:JSON options:kNilOptions error:nil];
   };
}

- (DFCacheDecodeBlock)blockJSONDecode {
   return ^id(NSData *data){
      return [NSJSONSerialization JSONObjectWithData:data options:kNilOptions error:nil];
   };
}

@end


#if TARGET_OS_IPHONE
@implementation DFCache (UIImage)

- (void)storeImage:(UIImage *)image imageData:(NSData *)data forKey:(NSString *)key {
    NSUInteger cost = self.blockUIImageCost(image);
    if (data) {
        [self storeObject:image forKey:key cost:cost data:data];
    } else {
        [self storeObject:image forKey:key cost:cost encode:self.blockUIImageEncode];
    }
}

- (void)cachedImageForKey:(NSString *)key completion:(void (^)(UIImage *))completion {
    [self cachedObjectForKey:key decode:self.blockUIImageDecode cost:self.blockUIImageCost completion:completion];
}

- (void)cachedImageForKeys:(NSArray *)keys completion:(void (^)(UIImage *, NSString *))completion{
    [self cachedObjectForKeys:keys decode:self.blockUIImageDecode cost:self.blockUIImageCost completion:completion];
}

@end
#endif


#pragma mark - DFCache (Shared) -

@implementation DFCache (Shared)

+ (instancetype)imageCache {
    static DFCache *_shared = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        _shared = [[DFCache alloc] initWithName:@"image_cache" memoryCache:[NSCache new]];
        _shared.diskCapacity = 1024 * 1024 * 120; // 120 Mb
        _shared.cleanupRate = 0.6;
        _shared.memoryCache.totalCostLimit = 1024 * 1024 * 15; // 15 Mb
    });
    return _shared;
}

@end
