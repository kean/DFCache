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


static CGFloat _kMetatableSyncInterval = 3.f; // Seconds.


typedef NSArray *(^DFCleanupBlock)(NSDictionary *);


@interface _DFCachePaths : NSObject

@property (nonatomic) NSString *root;
@property (nonatomic) NSString *entries;
@property (nonatomic) NSString *internals;
@property (nonatomic) NSString *metatable;

- (id)initWithName:(NSString *)name;
- (NSString *)entryPathWithName:(NSString *)name;

@end

@implementation _DFCachePaths

- (id)initWithName:(NSString *)name {
    if (self = [super init]) {
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES);
    _root = [paths[0] stringByAppendingPathComponent:name];
    _entries = [_root stringByAppendingPathComponent:@"entries"];
    _internals = [_root stringByAppendingPathComponent:@"internals"];
    _metatable = [_entries stringByAppendingPathComponent:@"metatable.plist"];
    }
    return self;
}

- (NSString *)entryPathWithName:(NSString *)name {
    return name ? [_entries stringByAppendingPathComponent:name] : nil;
}

@end


static
_dwarf_bytes
_dwarf_cache_size(NSArray *metatableValues) {
    _dwarf_bytes cacheSize = 0;
    for (NSDictionary *metadata in metatableValues) {
        cacheSize += [metadata[DFCacheMetaFileSizeKey] unsignedLongLongValue];
    }
    return cacheSize;
}

#pragma mark - DFCache -

@implementation DFCache {
    // Internals
    _DFCachePaths *_paths;
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
        
        _metaQueue = dispatch_queue_create("dwarf.cache.metaqueue", DISPATCH_QUEUE_SERIAL);
        _ioQueue = dispatch_queue_create("dwarf.cache.ioqueue", DISPATCH_QUEUE_SERIAL);
        _memoryCache = [NSCache new];
        _memoryCache.name = name;
        _name = name;
        
        _paths = [[_DFCachePaths alloc] initWithName:name];
        [self _initMetatableWithPath:_paths.metatable];
        [self _addNotificationObservers];
    }
    return self;
}

- (id)init {
    return [self initWithName:@"_df_cache_default"];
}

- (void)_addNotificationObservers {
    NSNotificationCenter *center = [NSNotificationCenter defaultCenter];
    [center addObserver:self selector:@selector(applicationWillResignActive:) name:DFApplicationWillResignActiveNotification object:nil];
    [center addObserver:self selector:@selector(applicationWillTerminate:) name:DFApplicationWillTerminateNotification object:nil];
}

- (void)_setDefaults {
    _settings.diskCacheCapacity = 1048576 * 100; // 100 Mb
    _settings.cleanupTargetSizeRatio = 2.0;
}

#pragma mark - Caching (Read)

- (void)objectForKey:(NSString *)key
               queue:(dispatch_queue_t)queue
           transform:(id (^)(NSData *))transform
          completion:(void (^)(id))completion {
    if (!completion) {
        return;
    }
    if (!key || !transform) {
        _dwarf_callback(queue, completion, nil);
        return;
    }
    dispatch_async(_metaQueue, ^{
        NSDictionary *metadata = _metatable[key];
        if (!metadata) { // Fastpath: cache fault
            _dwarf_callback(queue, completion, nil);
            return;
        }
        NSString *filename = metadata[DFCacheMetaFileNameKey];
        dispatch_async(_ioQueue, ^{
            @autoreleasepool {
                NSString *filepath = [_paths entryPathWithName:filename];
                NSData *data = [NSData dataWithContentsOfFile:filepath options:NSDataReadingUncached error:nil];
                id object = data ? transform(data) : nil;
                if (object) {
                    [_memoryCache setObject:object forKey:key];
                    [self _touchObjectForKey:key];
                }
                _dwarf_callback(queue, completion, object);
            }
        });
    });
}

- (void)_touchObjectForKey:(NSString *)key {
    dispatch_async(_metaQueue, ^{
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
    dispatch_async(_metaQueue, ^{
        NSString *filename = [DFCrypto MD5FromString:key];
        if (!filename) {
            return;
        }
        [self _storeMetadataForKey:key filename:filename data:data userValues:metadata];
        dispatch_async(_ioQueue, ^{
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
    metadata[DFCacheMetaCreationDateKey] = date;
    metadata[DFCacheMetaAccessDateKey] = date;
    metadata[DFCacheMetaFileNameKey] = filename;
    if (data) {
        metadata[DFCacheMetaFileSizeKey] = @(data.length);
    }
    [metadata addEntriesFromDictionary:keyedValues];
    _metatable[key] = metadata;
    [self _setNeedsSyncMetatable];
}

- (void)_storeObjectData:(NSData *)data filename:(NSString *)filename {
    [self _createCacheDirectories];
    NSString *filepath = [_paths entryPathWithName:filename];
    NSFileManager *manager = [NSFileManager defaultManager];
    [manager createFileAtPath:filepath contents:data attributes:nil];
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
        dispatch_sync(_metaQueue, ^{
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
        dispatch_async(_metaQueue, ^{
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
    dispatch_async(_ioQueue, ^{
        NSFileManager *manager = [NSFileManager defaultManager];
        for (NSString *filename in filenames) {
            NSString *filepath = [_paths entryPathWithName:filename];
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
        dispatch_async(_metaQueue, ^{
            [_metatable removeAllObjects];
            [self _setNeedsSyncMetatable];
            dispatch_async(_ioQueue, ^{
                [[NSFileManager defaultManager] removeItemAtPath:_paths.entries error:nil];
            });
        });
    }
}

- (void)removeAllObjects {
    [self removeAllObjects:(DFCacheRemoveFromDisk | DFCacheRemoveFromMemory)];
}

#pragma mark - Maintenance

- (void)cleanupDiskCache:(DFCleanupBlock)cleanupBlock {
    dispatch_async(_metaQueue, ^{
        NSArray *removeKeys = cleanupBlock(_metatable);
        [self _removeObjectsForKeys:removeKeys];
    });
}

- (void)cleanupDiskCache {
    [self cleanupDiskCache:[self _cleanupBlock]];
}

- (void)setDiskCleanupBlock:(DFCleanupBlock)cleanupBlock {
    dispatch_sync(_metaQueue, ^{
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
        if (_settings.diskCacheCapacity == 0) {
            return removeKeys;
        }
        
        NSMutableArray *metatableKeys, *metatableValues;
        [self _metatable:metatable getKeys:&metatableKeys values:&metatableValues];
        NSArray *values = [metatableValues sortedArrayUsingComparator:^NSComparisonResult(id obj1, id obj2) {
            return [obj1[DFCacheMetaAccessDateKey] compare:
                    obj2[DFCacheMetaAccessDateKey]];
        }];
        
        _dwarf_bytes cacheSize = _dwarf_cache_size(values);
        _dwarf_bytes targetSize = _settings.diskCacheCapacity / _settings.cleanupTargetSizeRatio;
        for (NSDictionary *value in values) {
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

- (void)_metatable:(NSDictionary *)metatable getKeys:(NSMutableArray **)keys values:(NSMutableArray **)values {
    NSUInteger count = [metatable count];
    id __unsafe_unretained _keys[count];
    id __unsafe_unretained _values[count];
    [metatable getObjects:_values andKeys:_keys];
    *keys = [NSMutableArray arrayWithObjects:_keys count:count];
    *values = [NSMutableArray arrayWithObjects:_values count:count];
}

- (_dwarf_bytes)diskCacheSize {
    __block _dwarf_bytes size = 0;
    dispatch_sync(_metaQueue, ^{
        size = _dwarf_cache_size([_metatable allValues]);
    });
    return size;
}

#pragma mark - Caching (Private)

- (void)_createCacheDirectories {
    [self _createDirectoryAtPath:_paths.root];
    [self _createDirectoryAtPath:_paths.entries];
    [self _createDirectoryAtPath:_paths.internals];
}

- (void)_createDirectoryAtPath:(NSString *)path {
    NSFileManager *manager = [NSFileManager defaultManager];
    if (![manager fileExistsAtPath:path]) {
        [manager createDirectoryAtPath:path withIntermediateDirectories:YES attributes:nil error:NULL];
    }
}

#pragma mark - Metatable (Private)

- (void)_initMetatableWithPath:(NSString *)path {
    _metatable = [NSMutableDictionary dictionaryWithContentsOfFile:path];
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
    
    dispatch_async(_metaQueue, ^{
        NSMutableArray *removeKeys = [NSMutableArray new];
        [_metatable enumerateKeysAndObjectsUsingBlock:^(id key, id obj, BOOL *stop) {
            NSString *filepath = [_paths entryPathWithName:obj[DFCacheMetaFileNameKey]];
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
    [_metatable writeToFile:_paths.metatable atomically:YES];
    _flags.needsSyncMetatable = NO;
}

#pragma mark - Application Notifications

- (void)applicationWillResignActive:(NSNotification *)notification {
    [self cleanupDiskCache];
}

- (void)applicationWillTerminate:(NSNotification *)notification {
    dispatch_sync(_metaQueue, ^{
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
