/*
 The MIT License (MIT)
 
 Copyright (c) 2013 Alexander Grebenyuk (github.com/kean).
 
 Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:
 
 The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.
 
 THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
 */

#import "DFCache.h"
#import "DFObjCExtenstions.h"

#import "dwarf_private.h"

#if TARGET_OS_IPHONE
#import "DFImageProcessing.h"
#endif


#pragma mark - DFCache -

@implementation DFCache {
    dispatch_queue_t _diskQueue;
    DFStorage *_metadataStorage;
    NSCache *_memorizedMetadata;
}

- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    DWARF_DISPATCH_RELEASE(_ioQueue);
}

- (id)initWithDiskCache:(DFDiskCache *)diskCache memoryCache:(NSCache *)memoryCache {
    if (self = [super init]) {
        NSAssert(diskCache, @"Attemting to initialize DFCache without disk cache");
        _diskCache = diskCache;
        _memoryCache = memoryCache;
        
        NSString *metadataName = [[_diskCache.path lastPathComponent] stringByAppendingString:@"-df_metadata"];
        NSString *metadataPath = [[self _cachesPath] stringByAppendingPathComponent:metadataName];
        _metadataStorage = [[DFStorage alloc] initWithPath:metadataPath];
        
        _memorizedMetadata = [NSCache new];
        _memorizedMetadata.countLimit = 50;
        
        _diskQueue = dispatch_queue_create("_df_storage_io_queue", DISPATCH_QUEUE_SERIAL);
        
        NSNotificationCenter *center = [NSNotificationCenter defaultCenter];
        [center addObserver:self selector:@selector(_applicationWillResignActive:) name:DFApplicationWillResignActiveNotification object:nil];
    }
    return self;
}

- (id)initWithName:(NSString *)name memoryCache:(NSCache *)memoryCache {
    if (!name.length) {
        [NSException raise:@"DFCache" format:@"Attemting to initialize DFCache without a name"];
    }
    NSString *storagePath = [[self _cachesPath] stringByAppendingPathComponent:name];
    
    DFDiskCache *storage = [[DFDiskCache alloc] initWithPath:storagePath];
    storage.diskCapacity = 1024 * 1024 * 100; // 100 Mb
    storage.cleanupRate = 0.5;
    return [self initWithDiskCache:storage memoryCache:memoryCache];
}

- (id)initWithName:(NSString *)name {
    NSCache *memoryCache = [NSCache new];
    memoryCache.totalCostLimit = 1024 * 1024 * 15; // 15 Mb
    return [self initWithName:name memoryCache:memoryCache];
}

- (NSString *)_cachesPath {
    return NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES)[0];
}

#pragma mark - Read

- (void)cachedObjectForKey:(NSString *)key decode:(DFCacheDecodeBlock)decode cost:(DFCacheCostBlock)cost completion:(void (^)(id))completion {
    if (!completion) {
        return;
    }
    if (!key) {
        _dwarf_callback(completion, nil);
        return;
    }
    id object = [_memoryCache objectForKey:key];
    if (object) {
        _dwarf_callback(completion, object);
        return;
    }
    dispatch_async(_diskQueue, ^{
        NSData *data = [_diskCache dataForKey:key];
        if (!data) {
            _dwarf_callback(completion, nil);
            return;
        }
        dispatch_async([self _processingQueue], ^{
            id object = decode(data);
            [self _touchObject:object forKey:key cost:cost];
            _dwarf_callback(completion, object);
        });
    });
}

- (id)cachedObjectForKey:(NSString *)key decode:(DFCacheDecodeBlock)decode cost:(DFCacheCostBlock)cost {
    if (!key || !decode) {
        return nil;
    }
    id object = [_memoryCache objectForKey:key];
    if (!object) {
        NSData *data = [_diskCache dataForKey:key];
        if (data) {
            object = decode(data);
            [self _touchObject:object forKey:key cost:cost];
        }
    }
    return object;
}

- (dispatch_queue_t)_processingQueue {
    return dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0);
}

#pragma mark - Read (Multiple Keys)

- (void)cachedObjectsForKeys:(NSArray *)keys decode:(DFCacheDecodeBlock)decode cost:(DFCacheCostBlock)cost completion:(void (^)(NSDictionary *))completion {
    if (!completion) {
        return;
    }
    if (!keys.count) {
        _dwarf_callback(completion, nil);
        return;
    }
    NSMutableArray *remainingKeys = [NSMutableArray arrayWithArray:keys];
    NSMutableDictionary *foundObjects = [NSMutableDictionary new];
    
    // Lookup objects into memory cache.
    for (NSString *key in keys) {
        id object = [_memoryCache objectForKey:key];
        if (object) {
            foundObjects[key] = object;
            [remainingKeys removeObject:key];
        }
    }
    if (!remainingKeys.count) {
        _dwarf_callback(completion, foundObjects);
        return;
    }
    
    // Lookup data for remaining keys into disk storage.
    dispatch_async(_diskQueue, ^{
        NSMutableDictionary *foundData = [NSMutableDictionary new];
        for (NSString *key in remainingKeys) {
            NSData *data = [_diskCache dataForKey:key];
            if (data) {
                foundData[key] = data;
            }
        }
        dispatch_async([self _processingQueue], ^{
            for (NSString *key in foundData) {
                NSData *data = foundData[key];
                id object = decode(data);
                if (object) {
                    [self _touchObject:foundObjects forKey:key cost:cost];
                    foundObjects[key] = object;
                }
            }
            _dwarf_callback(completion, foundObjects);
        });
    });
}

#pragma mark - Write

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
    if (data) {
        [_diskCache setData:data forKey:key];
    } else {
        dispatch_async([self _processingQueue], ^{
            [_diskCache setData:encode(object) forKey:key];
        });
    }
}

#pragma mark - Metadata

- (NSDictionary *)metadataForKey:(NSString *)key {
    if (!key) {
        return nil;
    }
    return [[self _metadataForKey:key] copy];
}

- (void)setMetadata:(NSDictionary *)metadata forKey:(NSString *)key {
    if (!metadata || !key) {
        return;
    }
    [_memorizedMetadata setObject:metadata forKey:key];
    NSData *data = [NSKeyedArchiver archivedDataWithRootObject:metadata];
    [_metadataStorage setData:data forKey:key];
}

- (void)setMetadataValues:(NSDictionary *)keyedValues forKey:(NSString *)key {
    if (!keyedValues || !key) {
        return;
    }
    NSMutableDictionary *metadata = [[NSMutableDictionary alloc] initWithDictionary:[self _metadataForKey:key]];
    [metadata addEntriesFromDictionary:keyedValues];
    [self setMetadata:metadata forKey:key];
}

- (NSDictionary *)_metadataForKey:(NSString *)key {
    NSDictionary *metadata = [_memorizedMetadata objectForKey:key];
    if (!metadata) {
        NSData *data = [_metadataStorage dataForKey:key];
        metadata = [NSKeyedUnarchiver unarchiveObjectWithData:data];
        if (metadata) {
            [_memorizedMetadata setObject:metadata forKey:key];
        }
    }
    return metadata;
}

- (void)removeMetadataForKey:(NSString *)key {
    if (!key) {
        return;
    }
    [_memorizedMetadata removeObjectForKey:key];
    [_metadataStorage removeDataForKey:key];
}

#pragma mark - Remove

- (void)removeObjectsForKeys:(NSArray *)keys {
    if (!keys) {
        return;
    }
    for (NSString *key in keys) {
        [_memoryCache removeObjectForKey:key];
        [_memorizedMetadata removeObjectForKey:key];
    }
    dispatch_async(_diskQueue, ^{
        for (NSString *key in keys) {
            [_diskCache removeDataForKey:key];
            [_metadataStorage removeDataForKey:key];
        }
    });
}

- (void)removeObjectForKey:(NSString *)key {
    if (key) {
        [self removeObjectsForKeys:@[key]];
    }
}

- (void)removeAllObjects {
    [_memoryCache removeAllObjects];
    [_memorizedMetadata removeAllObjects];
    dispatch_async(_diskQueue, ^{
        [_diskCache removeAllData];
        [_metadataStorage removeAllData];
    });
}

#pragma mark - Private

- (void)_touchObject:(id)object forKey:(NSString *)key cost:(DFCacheCostBlock)cost {
    if (!object || !key) {
        return;
    }
    NSUInteger objectCost = cost ? cost(object) : 0;
    [_memoryCache setObject:object forKey:key cost:objectCost];
}

-(void)_applicationWillResignActive:(NSNotification *)notification {
    // Delay cleanup by scheduling in main thread in NSDefaultRunLoopMode.
    [self performSelector:@selector(_cleanupDisk) withObject:self afterDelay:2.0];
}

- (void)_cleanupDisk {
    dispatch_async(_diskQueue, ^{
        [_diskCache cleanup];
    });
}

@end


#pragma mark - DFCache (Blocks) -

@implementation DFCache (Blocks)

#if TARGET_OS_IPHONE
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

- (DFCacheCostBlock)blockUIImageCost {
    return ^NSUInteger(id object){
        UIImage *image = safe_cast(UIImage, object);
        if (image) {
            return CGImageGetWidth(image.CGImage) * CGImageGetHeight(image.CGImage) * 4;
        }
        return 0;
    };
}
#endif

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

- (DFCacheEncodeBlock)blockNSCodingEncode {
    return ^NSData *(id<NSCoding> object){
        return [NSKeyedArchiver archivedDataWithRootObject:object];
    };
}

- (DFCacheDecodeBlock)blockNSCodingDecode {
    return ^id<NSCoding>(NSData *data){
        return [NSKeyedUnarchiver unarchiveObjectWithData:data];
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

@end
#endif


#pragma mark - DFCache (Shared) -

@implementation DFCache (Shared)

+ (instancetype)imageCache {
    static DFCache *_shared = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        _shared = [[DFCache alloc] initWithName:@"image_cache" memoryCache:[NSCache new]];
        _shared.diskCache.diskCapacity = 1024 * 1024 * 120; // 120 Mb
        _shared.diskCache.cleanupRate = 0.6;
        _shared.memoryCache.totalCostLimit = 1024 * 1024 * 15; // 15 Mb
    });
    return _shared;
}

@end
