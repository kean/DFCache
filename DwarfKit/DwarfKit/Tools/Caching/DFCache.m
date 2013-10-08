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


@interface _DFCachePaths : NSObject

@property (nonatomic) NSString *root;
@property (nonatomic) NSString *entries;
@property (nonatomic) NSString *metadata;

- (id)initWithName:(NSString *)name;
- (NSString *)entryPathWithName:(NSString *)name;

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

- (NSString *)fileNameWithKey:(NSString *)key {
    return [DFCrypto MD5FromString:key];
}

- (NSString *)entryPathWithKey:(NSString *)key {
    NSString *filename = [self fileNameWithKey:key];
    return [self entryPathWithName:filename];
}

- (NSString *)metadataPathWithKey:(NSString *)key {
    NSString *filename = [self fileNameWithKey:key];
    return [self metadataPathWithName:filename];
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
}

- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    DWARF_DISPATCH_RELEASE(_ioQueue);
}

- (id)initWithName:(NSString *)name {
    if ((self = [super init])) {
        if (!name) {
            return nil;
        }
        [self _setDefaults];
        
        _ioQueue = dispatch_queue_create("dwarf.cache.ioqueue", DISPATCH_QUEUE_SERIAL);
        
        _memoryCache = [NSCache new];
        _memoryCache.name = name;
        _name = name;
        
        _paths = [[_DFCachePaths alloc] initWithName:name];
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
}

- (void)_setDefaults {
    _settings.diskCacheCapacity = 1024 * 1024 * 100; // 100 Mb
    _settings.cleanupTargetSizeRatio = 0.5;
}

#pragma mark - Caching (Read)

- (void)cachedObjectForKey:(NSString *)key
                     queue:(dispatch_queue_t)queue
                 transform:(id (^)(NSData *))transform
                completion:(void (^)(id))completion {
    if (!completion) {
        return;
    }
    if (!key) {
        _dwarf_callback(queue, completion, nil);
        return;
    }
    if (!transform) {
        transform = ^(NSData *data){
            return data;
        };
    }
    [self _cachedObjectForKey:key
                        queue:queue
                    transform:transform
                   completion:completion];
}

- (void)_cachedObjectForKey:(NSString *)key
                      queue:(dispatch_queue_t)queue
                  transform:(id (^)(NSData *))transform
                 completion:(void (^)(id))completion {
    id object = [_memoryCache objectForKey:key];
    if (object) {
        _dwarf_callback(queue, completion, object);
        return;
    }
    dispatch_async(_ioQueue, ^{
        NSString *filepath = [_paths entryPathWithKey:key];
        NSData *data = [NSData dataWithContentsOfFile:filepath options:NSDataReadingUncached error:nil];
        if (!data) {
            _dwarf_callback(queue, completion, nil);
            return;
        }
        id object = transform(data);
        if (object) {
            [_memoryCache setObject:object forKey:key];
            [self _touchObjectWithPath:filepath];
        }
        _dwarf_callback(queue, completion, object);
    });
}

- (void)_touchObjectWithPath:(NSString *)path {
    NSURL *url = [NSURL fileURLWithPath:path];
    [url setResourceValue:[NSDate date] forKey:NSURLAttributeModificationDateKey error:nil];
}

- (id)cachedObjectForKey:(NSString *)key {
    return key ? [_memoryCache objectForKey:key] : nil;
}

#pragma mark - Caching (Write)

- (void)storeObject:(id)object
             forKey:(NSString *)key
               cost:(NSUInteger)cost
          transform:(NSData *(^)(id))transform {
    [self _storeObject:object forKey:key cost:cost data:nil transform:transform];
}

- (void)storeObject:(id)object
             forKey:(NSString *)key
               cost:(NSUInteger)cost
               data:(NSData *)data {
    [self _storeObject:object forKey:key cost:cost data:data transform:nil];
}

- (void)_storeObject:(id)object
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
    dispatch_async(_ioQueue, ^{
        NSData *objData = data ? data : transform(object);
        [self _storeObjectData:objData forKey:key];
    });
}

- (void)_storeObjectData:(NSData *)data forKey:(NSString *)key {
    [self _createCacheDirectories];
    NSString *filepath = [_paths entryPathWithKey:key];
    NSFileManager *manager = [NSFileManager defaultManager];
    [manager createFileAtPath:filepath contents:data attributes:nil];
}

#pragma mark - Metadata

- (NSDictionary *)metadataForKey:(NSString *)key {
    NSString *filepath = [_paths metadataPathWithKey:key];
    return [NSDictionary dictionaryWithContentsOfFile:filepath];
}

- (void)setMetadata:(NSDictionary *)metadata forKey:(NSString *)key {
    NSString *filepath = [_paths metadataPathWithKey:key];
    [metadata writeToFile:filepath atomically:YES];
}

- (void)setMetadataValues:(NSDictionary *)keyedValues forKey:(NSString *)key {
    if (!keyedValues || !key) {
        return;
    }
    NSMutableDictionary *metadata = [[NSMutableDictionary alloc] initWithDictionary:[self metadataForKey:key]];
    [metadata addEntriesFromDictionary:keyedValues];
    [self setMetadata:metadata forKey:key];
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
        NSString *filename = [_paths fileNameWithKey:key];
        NSString *filepath = [_paths entryPathWithName:filename];
        [manager removeItemAtPath:filepath error:nil];
        NSString *metadataPath = [_paths metadataPathWithName:filename];
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

- (void)cleanupDiskCache {
    if (_settings.diskCacheCapacity == 0) {
        return;
    }
    dispatch_async(_ioQueue, ^{
        [self _cleanupDiskCache];
    });
}

- (void)_cleanupDiskCache {
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
    
    if (currentSize > _settings.diskCacheCapacity) {
        const _dwarf_bytes desiredSize = _settings.diskCacheCapacity * 0.5;
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

- (_dwarf_bytes)diskCacheSize {
    return 0; // TODO: Implement disk cache size
}

#pragma mark - Caching (Private)

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

#pragma mark - Application Notifications

- (void)applicationWillResignActive:(NSNotification *)notification {
    [self cleanupDiskCache];
}

#pragma mark - <DFImageCaching>

#if TARGET_OS_IPHONE

- (void)storeImage:(UIImage *)image imageData:(NSData *)imageData forKey:(NSString *)key {
    NSUInteger cost = image.size.width * image.size.height * [UIScreen mainScreen].scale;
    [self storeObject:image forKey:key cost:cost data:imageData];
}

- (void)imageForKey:(NSString *)key queue:(dispatch_queue_t)queue completion:(void (^)(UIImage *))completion {
    [self cachedObjectForKey:key queue:queue transform:^id(NSData *data) {
        return [DFImageProcessing decompressedImageWithData:data];
    } completion:completion];
}

- (UIImage *)imageForKey:(NSString *)key {
    return [self.memoryCache objectForKey:key];
}

#endif

#pragma mark - <NSCoding>

- (void)storeCodingObject:(id<NSCoding>)object metadata:(NSDictionary *)metadata cost:(NSUInteger)cost forKey:(NSString *)key {
    [self storeObject:object forKey:key cost:cost transform:^NSData *(id object) {
        return [NSKeyedArchiver archivedDataWithRootObject:object];
    }];
}

- (void)codingObjectForKey:(NSString *)key queue:(dispatch_queue_t)queue completion:(void (^)(id))completion {
    [self cachedObjectForKey:key queue:queue transform:^id(NSData *data) {
        return [NSKeyedUnarchiver unarchiveObjectWithData:data];
    } completion:completion];
}

@end
