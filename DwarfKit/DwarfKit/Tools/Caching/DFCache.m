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
    DFStorage *_metadataStorage;
    NSCache *_memorizedMetadata;
}

- (id)initWithDiskCache:(DFStorage *)diskCache memoryCache:(NSCache *)memoryCache {
    if (self = [super init]) {
        NSAssert(diskCache, @"Attemting to initialize DFCache without disk cache");
        _diskCache = diskCache;
        _memoryCache = memoryCache;
        
        NSString *metadataStorageName = [_diskCache.name stringByAppendingString:@"-metadata"];
        _metadataStorage = [[DFStorage alloc] initWithName:metadataStorageName];
        
        _memorizedMetadata = [NSCache new];
        _memorizedMetadata.countLimit = 50;
    }
    return self;
}

- (id)initWithName:(NSString *)name memoryCache:(NSCache *)memoryCache {
    if (!name.length) {
        [NSException raise:@"DFCache" format:@"Attemting to initialize DFCache without a name"];
    }
    DFStorage *storage = [[DFStorage alloc] initWithName:name];
    storage.diskCapacity = 1024 * 1024 * 100; // 100 Mb
    storage.cleanupRate = 0.5;
    return [self initWithDiskCache:storage memoryCache:memoryCache];
}

- (id)initWithName:(NSString *)name {
    NSCache *memoryCache = [NSCache new];
    memoryCache.totalCostLimit = 1024 * 1024 * 15; // 15 Mb
    return [self initWithName:name memoryCache:memoryCache];
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
    [_diskCache readDataForKey:key completion:^(NSData *data) {
        if (!data) {
            completion(nil);
            return;
        }
        dispatch_async([self _processingQueue], ^{
            id object = decode(data);
            if (object) {
                [self _touchObject:object forKey:key cost:cost];
            }
            _dwarf_callback(completion, object);
        });
    }];
}

- (id)cachedObjectForKey:(NSString *)key decode:(DFCacheDecodeBlock)decode cost:(DFCacheCostBlock)cost {
    if (!key || !decode) {
        return nil;
    }
    id object = [_memoryCache objectForKey:key];
    if (!object) {
        NSData *data = [_diskCache readDataForKey:key];
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
    [_diskCache readBatchForKeys:remainingKeys completion:^(NSDictionary *batch) {
        if (!batch.count) {
            _dwarf_callback(completion, foundObjects);
            return;
        }
        dispatch_async([self _processingQueue], ^{
            for (NSString *key in batch) {
                NSData *data = batch[key];
                id object = decode(data);
                if (object) {
                    [self _touchObject:foundObjects forKey:key cost:cost];
                    foundObjects[key] = object;
                }
            }
            _dwarf_callback(completion, foundObjects);
        });
    }];
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
        [_diskCache writeData:data forKey:key];
    } else {
        dispatch_async([self _processingQueue], ^{
            [_diskCache writeData:encode(object) forKey:key];
        });
    }
}

#pragma mark - Metadata

- (NSDictionary *)metadataForKey:(NSString *)key {
    if (!key) {
        return nil;
    }
    NSDictionary *metadata = [_memorizedMetadata objectForKey:key];
    if (!metadata) {
        NSData *data = [_metadataStorage readDataForKey:key];
        metadata = [NSKeyedUnarchiver unarchiveObjectWithData:data];
        if (metadata) {
            [_memorizedMetadata setObject:metadata forKey:key];
        }
    }
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
    NSDictionary *metadata = [_memorizedMetadata objectForKey:key];
    if (metadata) {
        _dwarf_callback(completion, metadata);
        return;
    }
    [_metadataStorage readDataForKey:key completion:^(NSData *data) {
        NSDictionary *metadata = [NSKeyedUnarchiver unarchiveObjectWithData:data];
        if (metadata) {
            [_memorizedMetadata setObject:metadata forKey:key];
        }
        completion([metadata copy]);
    }];
}

- (void)setMetadata:(NSDictionary *)metadata forKey:(NSString *)key {
    if (!metadata || !key) {
        return;
    }
    [_memorizedMetadata setObject:metadata forKey:key];
    NSData *data = [NSKeyedArchiver archivedDataWithRootObject:metadata];
    [_metadataStorage writeData:data forKey:key];
}

- (void)setMetadataValues:(NSDictionary *)keyedValues forKey:(NSString *)key {
    if (!keyedValues || !key) {
        return;
    }
    NSMutableDictionary *metadata = [[NSMutableDictionary alloc] initWithDictionary:[_memorizedMetadata objectForKey:key]];
    if (metadata) {
        [self setMetadata:metadata forKey:key];
        return;
    }
    [_metadataStorage readDataForKey:key completion:^(NSData *data) {
        NSMutableDictionary *metadata = [[NSMutableDictionary alloc] initWithDictionary:[NSKeyedUnarchiver unarchiveObjectWithData:data]];
        if (metadata) {
            [metadata addEntriesFromDictionary:keyedValues];
            [self setMetadata:metadata forKey:key];
        }
    }];
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
    [_diskCache removeDataForKeys:keys];
    [_metadataStorage removeDataForKeys:keys];
}

- (void)removeObjectForKey:(NSString *)key {
    if (key) {
        [self removeObjectsForKeys:@[key]];
    }
}

- (void)removeAllObjects {
    [_memoryCache removeAllObjects];
    [_memorizedMetadata removeAllObjects];
    [_diskCache removeAllData];
    [_metadataStorage removeAllData];
}

#pragma mark - Private

- (void)_touchObject:(id)object forKey:(NSString *)key cost:(DFCacheCostBlock)cost {
    if (!object || !key) {
        return;
    }
    NSUInteger objectCost = cost ? cost(object) : 0;
    [_memoryCache setObject:object forKey:key cost:objectCost];
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
