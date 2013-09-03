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

#import "dwarf_private.h"

#if TARGET_OS_IPHONE
#import "DFImageProcessing.h"
#endif


typedef unsigned long long _dwarf_bytes;
typedef NSArray *(^DFCleanupBlock)(NSDictionary *);


static inline
BOOL
_dwarf_entry_is_expired(NSDictionary *metadata) {
    NSDate *currentDate = [NSDate date];
    NSDate *expirationDate = metadata[DFCacheMetaExpirationDateKey];
    if (!expirationDate) {
        return NO;
    }
    return [currentDate compare:expirationDate] == NSOrderedDescending;
}


static
_dwarf_bytes
_dwarf_cache_size(NSArray *metatableValues) {
    _dwarf_bytes cacheSize = 0;
    for (NSDictionary *metadata in metatableValues) {
        cacheSize += [metadata[DFCacheMetaFileSizeKey] unsignedLongLongValue];
    }
    return cacheSize;
}


static CGFloat _kMetatableSyncInterval = 2.f; // Seconds


#pragma mark - DFCache -

@implementation DFCache {
    // Directories
    NSString *_rootFolder;
    NSString *_entriesFolder;
    NSString *_internalsFolder;
    NSString *_metatableFilepath;
    
    // Internals
    dispatch_queue_t _metaQueue;
    dispatch_queue_t _ioQueue;
    NSMutableDictionary *_metatable;
    DFCleanupBlock _cleanupBlock;
    
    struct {
        unsigned int needsSyncMetatable:1;
    } _flags;
}


- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    DWARF_DISPATCH_RELEASE(_metaQueue);
    DWARF_DISPATCH_RELEASE(_ioQueue);
    
}


- (id)initWithName:(NSString *)name {
    if ((self = [super init])) {
        if (!name) {
            return nil;
        }
        
        [self _setDefaults];
        
        _metaQueue = dispatch_queue_create("dwarf.cache.metaqueue", DISPATCH_QUEUE_CONCURRENT);
        _ioQueue = dispatch_queue_create("dwarf.cache.ioqueue", DISPATCH_QUEUE_CONCURRENT);
        
        _memoryCache = [NSCache new];
        _memoryCache.name = name;
        _name = name;
        
        [self _initPathsWithName:name];
        [self _initMetatable];
        
        NSNotificationCenter *center = [NSNotificationCenter defaultCenter];
        [center addObserver:self selector:@selector(applicationWillResignActive:) name:DFApplicationWillResignActiveNotification object:nil];
        [center addObserver:self selector:@selector(applicationWillTerminate:) name:DFApplicationWillTerminateNotification object:nil];
    }
    return self;
}


- (id)init {
    return [self initWithName:@"_df_cache_default"];
}


- (void)_setDefaults {
    _settings.filesExpirationPeriod = 60 * 60 * 24 * 7 * 4; // 4 weeks
    _settings.diskCacheCapacity = 1048576 * 100; // 100 Mb
    _settings.cleanupTargetSizeRatio = 2.0;
}


- (void)_initPathsWithName:(NSString *)name {
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES);
    _rootFolder = [paths[0] stringByAppendingPathComponent:name];
    _entriesFolder = [_rootFolder stringByAppendingPathComponent:@"entries"];
    _internalsFolder = [_rootFolder stringByAppendingPathComponent:@"internals"];
    _metatableFilepath = [_internalsFolder stringByAppendingPathComponent:@"metatable.plist"];
}

#pragma mark - Caching (Read)

- (void)objectForKey:(NSString *)key
               queue:(dispatch_queue_t)queue
           transform:(id (^)(NSData *))transform
          completion:(void (^)(id))completion {
    if (!completion) {
        return;
    }
    
    if (!queue) {
        queue = dispatch_get_main_queue();
    }
    
    if (!key || !transform) {
        dispatch_async(queue, ^{
            completion(nil);
        });
        return;
    }
    
    [self _objectForKey:key queue:queue transform:transform completion:completion];
}


- (void)_objectForKey:(NSString *)key
                queue:(dispatch_queue_t)queue
            transform:(id (^)(NSData *))transform
           completion:(void (^)(id))completion {
    dispatch_async(_metaQueue, ^{
        NSDictionary *metadata = _metatable[key];
        
        if (!metadata) { // Fastpath: cache fault
            dispatch_async(queue, ^{
                completion(nil);
            });
            return;
        }
        
        if (_dwarf_entry_is_expired(metadata)) {
            dispatch_async(queue, ^{
                completion(nil);
            });
            [self _removeObjectsForKeys:@[key]];
            return;
        }
        
        NSString *filename = metadata[DFCacheMetaFileNameKey];
        
        dispatch_async(_ioQueue, ^{
            @autoreleasepool {
                NSString *filepath = [self _filePathWithName:filename];
                NSData *data = [NSData dataWithContentsOfFile:filepath];
                id object = data ? transform(data) : nil;
                if (object) {
                    [_memoryCache setObject:object forKey:key];
                    [self _touchObjectForKey:key];
                }
                
                dispatch_async(queue, ^{
                    completion(object);
                });
            }
        });
    });
}


- (void)_touchObjectForKey:(NSString *)key {
    dispatch_barrier_async(_metaQueue, ^{
        NSMutableDictionary *metadata = _metatable[key];
        metadata[DFCacheMetaAccessDateKey] = [NSDate date];
    });
}


- (id)objectForKey:(NSString *)key {
    return key ? [_memoryCache objectForKey:key] : nil;
}

#pragma mark - Caching (Write)

- (void)storeObject:(id)object
           metadata:(NSDictionary *)metadata
             forKey:(NSString *)key
               cost:(NSUInteger)cost
               data:(NSData *)data
          transform:(NSData *(^)(id object))transform {
    if (!object || !key) {
        return;
    }
    
    [_memoryCache setObject:object forKey:key cost:cost];
    
    if (!data && !transform) {
        return;
    }
    
    dispatch_barrier_async(_metaQueue, ^{
        NSString *filename = [DFCrypto MD5FromString:key];
        if (!filename) {
            return;
        }
        
        [self _storeMetadataForKey:key filename:filename data:data userValues:metadata];
        
        dispatch_barrier_async(_ioQueue, ^{
            NSData *objData = data ? data : transform(object);
            [self _storeObjectData:objData filename:filename];
            
            if (!data) {
                NSDictionary *sizeValue = @{ DFCacheMetaFileSizeKey : @(objData.length) };
                [self setMetadataValues:sizeValue forKey:key];
            }
        });
    });
}


- (void)storeObject:(id)object forKey:(NSString *)key data:(NSData *)data transform:(NSData *(^)(id))transform {
    [self storeObject:object metadata:nil forKey:key cost:0 data:data transform:transform];
}


- (void)_storeMetadataForKey:(NSString *)key filename:(NSString *)filename data:(NSData *)data userValues:(NSDictionary *)keyedValues {
    NSMutableDictionary *metadata = [NSMutableDictionary new];
    
    NSDate *date = [NSDate date];
    NSDate *expirationDate = [date dateByAddingTimeInterval:_settings.filesExpirationPeriod];
    
    metadata[DFCacheMetaCreationDateKey] = date;
    metadata[DFCacheMetaAccessDateKey] = date;
    metadata[DFCacheMetaFileNameKey] = filename;
    
    if (data) {
        metadata[DFCacheMetaFileSizeKey] = @(data.length);
    }
    
    if (_settings.filesExpirationPeriod > 0 && expirationDate) {
        metadata[DFCacheMetaExpirationDateKey] = expirationDate;
    }
    
    [metadata addEntriesFromDictionary:keyedValues];
    
    _metatable[key] = metadata;
    [self _setNeedsSyncMetatable];
}


- (void)_storeObjectData:(NSData *)data filename:(NSString *)filename {
    [self _createCacheDirectories];
    [[NSFileManager defaultManager] createFileAtPath:[self _filePathWithName:filename] contents:data attributes:nil];
}


- (void)storeObject:(id)object forKey:(NSString *)key cost:(NSUInteger)cost {
    [_memoryCache setObject:object forKey:key cost:cost];
}


- (void)storeObject:(id)object forKey:(NSString *)key {
    [_memoryCache setObject:object forKey:key];
}

#pragma mark - Metadata

- (NSDictionary *)metadataForKey:(NSString *)key {
    __block NSDictionary *metadata;
    dispatch_sync(_metaQueue, ^{
        metadata = key ? _metatable[key] : nil;
    });
    return [metadata copy];
}


- (void)setMetadataValues:(NSDictionary *)keyedValues forKey:(NSString *)key {
    if (keyedValues && key) {
        dispatch_barrier_sync(_metaQueue, ^{
            NSMutableDictionary *metadata = _metatable[key];
            [metadata addEntriesFromDictionary:keyedValues];
        });
    }
}

#pragma mark - Caching (Remove)

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
        dispatch_barrier_async(_metaQueue, ^{
            [self _removeObjectsForKeys:keys];
        });
    }
}


- (void)_removeObjectsForKeys:(NSArray *)keys {
    NSMutableArray *filenames = [NSMutableArray new];
    for (NSString *key in keys) {
        NSDictionary *metadata = _metatable[key];
        NSString *filename = metadata[DFCacheMetaFileNameKey];
        if (filename) {
            [filenames addObject:filename];
        }
    }
    
    [_metatable removeObjectsForKeys:keys];
    [self _setNeedsSyncMetatable];
    
    dispatch_barrier_async(_ioQueue, ^{
        NSFileManager *manager = [NSFileManager defaultManager];
        for (NSString *filename in filenames) {
            NSString *filepath = [self _filePathWithName:filename];
            [manager removeItemAtPath:filepath error:nil];
        }
    });
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
        dispatch_barrier_async(_metaQueue, ^{
            [_metatable removeAllObjects];
            [self _setNeedsSyncMetatable];
            dispatch_barrier_async(_ioQueue, ^{
                [[NSFileManager defaultManager] removeItemAtPath:_entriesFolder error:nil];
            });
        });
    }
}


- (void)removeAllObjects {
    [self removeAllObjects:(DFCacheRemoveFromDisk | DFCacheRemoveFromMemory)];
}

#pragma mark - Maintenance


- (void)cleanupDiskCache:(DFCleanupBlock)cleanupBlock {
    dispatch_barrier_async(_metaQueue, ^{
        NSArray *removeKeys = cleanupBlock(_metatable);
        [self _removeObjectsForKeys:removeKeys];
    });
}


- (void)cleanupDiskCache {
    [self cleanupDiskCache:[self _cleanupBlock]];
}


- (void)setDiskCleanupBlock:(DFCleanupBlock)cleanupBlock {
    dispatch_barrier_sync(_metaQueue, ^{
        _cleanupBlock = [cleanupBlock copy];
    });
}


- (DFCleanupBlock)_cleanupBlock {
    if (!_cleanupBlock) {
        _cleanupBlock = [[self _defaultCleanupBlock] copy];
    }
    return _cleanupBlock;
}


- (DFCleanupBlock)_defaultCleanupBlock {
    return ^(NSDictionary *metatable){
        NSMutableArray *removeKeys = [NSMutableArray new];
        
        NSUInteger count = [metatable count];
        id __unsafe_unretained keys[count];
        id __unsafe_unretained objects[count];
        [metatable getObjects:objects andKeys:keys];
        
        NSMutableArray *metatableKeys = [NSMutableArray arrayWithObjects:keys count:count];
        NSMutableArray *metatableValues = [NSMutableArray arrayWithObjects:objects count:count];
        
        // Remove expired files.
        // =============================
        NSIndexSet *expiredIndexes = [metatableValues indexesOfObjectsPassingTest:^BOOL(id obj, NSUInteger idx, BOOL *stop) {
            return _dwarf_entry_is_expired(obj);
        }];
        [removeKeys addObjectsFromArray:[metatableKeys objectsAtIndexes:expiredIndexes]];
        
        // Remove remaining files (until fit target size).
        // ===============================================
        if (_settings.diskCacheCapacity == 0) {
            return removeKeys;
        }
        
        [metatableValues removeObjectsAtIndexes:expiredIndexes];
        [metatableKeys removeObjectsAtIndexes:expiredIndexes];
        
        NSArray *remainingValues = [metatableValues sortedArrayUsingComparator:^NSComparisonResult(id obj1, id obj2) {
            return [obj1[DFCacheMetaAccessDateKey] compare:
                    obj2[DFCacheMetaAccessDateKey]];
        }];
        
        _dwarf_bytes cacheSize = _dwarf_cache_size(remainingValues);
        _dwarf_bytes targetSize = _settings.diskCacheCapacity / _settings.cleanupTargetSizeRatio;
        for (NSDictionary *value in remainingValues) {
            if (cacheSize <= targetSize) {
                break;
            }
            NSUInteger index = [metatableValues indexOfObject:value];
            [removeKeys addObject:metatableKeys[index]];
            cacheSize -= [value[DFCacheMetaFileSizeKey] unsignedLongLongValue];
        }
        
        return removeKeys;
    };
}


- (_dwarf_bytes)diskCacheSize {
    __block _dwarf_bytes size = 0;
    dispatch_sync(_metaQueue, ^{
        size = _dwarf_cache_size([_metatable allValues]);
    });
    return size;
}

#pragma mark - Caching (Private)

- (NSString *)_filePathWithName:(NSString *)name {
    return name ? [_entriesFolder stringByAppendingPathComponent:name] : nil;
}


- (void)_createCacheDirectories {
    [self _createDirectoryAtPath:_rootFolder];
    [self _createDirectoryAtPath:_entriesFolder];
    [self _createDirectoryAtPath:_internalsFolder];
}


- (void)_createDirectoryAtPath:(NSString *)path {
    NSFileManager *manager = [NSFileManager defaultManager];
    if (![manager fileExistsAtPath:path]) {
        [manager createDirectoryAtPath:path withIntermediateDirectories:YES attributes:nil error:NULL];
    }
}

#pragma mark - Metatable (Private)

- (void)_initMetatable {
    _metatable = [NSMutableDictionary dictionaryWithContentsOfFile:_metatableFilepath];
    if (_metatable) {
        [self _validateMetatable];
    } else {
        _metatable = [NSMutableDictionary new];
    }
}


- (void)_validateMetatable {
    NSFileManager *manager = [NSFileManager defaultManager];
    
    void (^validateFilesize)(NSMutableDictionary *, NSString *) = ^(NSMutableDictionary *metadata, NSString *filepath){
        id filesize = metadata[DFCacheMetaFileSizeKey];
        if (!filesize) {
            NSDictionary *attributes = [manager attributesOfItemAtPath:filepath error:nil];
            if (attributes) {
                _dwarf_bytes size = [attributes fileSize];
                metadata[DFCacheMetaFileSizeKey] = @(size);
            }
        }
    };
    
    dispatch_barrier_async(_metaQueue, ^{
        NSMutableArray *removeKeys = [NSMutableArray new];
        
        [_metatable enumerateKeysAndObjectsUsingBlock:^(id key, id obj, BOOL *stop) {
            NSString *filepath = [self _filePathWithName:obj[DFCacheMetaFileNameKey]];
            if (![manager fileExistsAtPath:filepath]) {
                [removeKeys addObject:key];
            } else {
                validateFilesize(obj, filepath);
            }
        }];
        
        [_metatable removeObjectsForKeys:removeKeys];
    });
}


- (void)_setNeedsSyncMetatable {
    if (_flags.needsSyncMetatable) {
        return;
    }
    
    _flags.needsSyncMetatable = YES;
    dispatch_time_t popTime = dispatch_time(DISPATCH_TIME_NOW, (int64_t)(_kMetatableSyncInterval * NSEC_PER_SEC));
    dispatch_after(popTime, _metaQueue, ^(void){
        if (_flags.needsSyncMetatable) {
            [self _syncMetatable];
        }
    });
}


- (void)_syncMetatable {
    [self _createCacheDirectories];
    [_metatable writeToFile:_metatableFilepath atomically:YES];
    _flags.needsSyncMetatable = NO;
}

#pragma mark - Application Notifications

- (void)applicationWillResignActive:(NSNotification *)notification {
    [self cleanupDiskCache];
}


- (void)applicationWillTerminate:(NSNotification *)notification {
    dispatch_barrier_sync(_metaQueue, ^{
        [self _syncMetatable];
    });
}

#pragma mark - <DFImageCaching>

#if TARGET_OS_IPHONE

- (void)storeImage:(UIImage *)image imageData:(NSData *)imageData forKey:(NSString *)key {
    NSUInteger cost = image.size.width * image.size.height * [UIScreen mainScreen].scale;
    [self storeObject:image metadata:nil forKey:key cost:cost data:imageData transform:^NSData *(id object) {
        return UIImageJPEGRepresentation(object, 1.f);
    }];
}


- (void)imageForKey:(NSString *)key queue:(dispatch_queue_t)queue completion:(void (^)(UIImage *))completion {
    [self objectForKey:key queue:queue transform:^id(NSData *data) {
        return [DFImageProcessing decompressedImageWithData:data];
    } completion:completion];
}


- (UIImage *)imageForKey:(NSString *)key {
    return [self objectForKey:key];
}

#endif

#pragma mark - <NSCoding>

- (void)storeCodingObject:(id<NSCoding>)object metadata:(NSDictionary *)metadata cost:(NSUInteger)cost forKey:(NSString *)key {
    [self storeObject:object metadata:metadata forKey:key cost:cost data:nil transform:^NSData *(id object) {
        return [NSKeyedArchiver archivedDataWithRootObject:object];
    }];
}


- (void)codingObjectForKey:(NSString *)key queue:(dispatch_queue_t)queue completion:(void (^)(id))completion {
    [self objectForKey:key queue:queue transform:^id(NSData *data) {
        return [NSKeyedUnarchiver unarchiveObjectWithData:data];
    } completion:completion];
}

@end
