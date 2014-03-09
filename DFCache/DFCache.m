/*
 The MIT License (MIT)
 
 Copyright (c) 2013 Alexander Grebenyuk (github.com/kean).
 
 Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:
 
 The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.
 
 THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
 */

#import "DFCache.h"
#import "DFCachePrivate.h"
#import "DFCacheTimer.h"
#import "NSURL+DFExtendedFileAttributes.h"

NSString *const DFCacheAttributeMetadataKey = @"_df_cache_metadata_key";

@implementation DFCache {
    BOOL _cleanupTimerEnabled;
    NSTimeInterval _cleanupTimeInterval;
    DFCacheTimer *__weak _cleanupTimer;
}

- (void)dealloc {
    [_cleanupTimer invalidate];
}

- (id)initWithDiskCache:(DFDiskCache *)diskCache memoryCache:(NSCache *)memoryCache {
    if (self = [super init]) {
        if (!diskCache) {
            [NSException raise:NSInvalidArgumentException format:@"Attempting to initialize DFCache without disk cache"];
        }
        _diskCache = diskCache;
        _memoryCache = memoryCache;
        
        _ioQueue = dispatch_queue_create("_df_storage_io_queue", DISPATCH_QUEUE_SERIAL);
        _processingQueue = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0);
        
        _cleanupTimeInterval = 60.f;
        _cleanupTimerEnabled = YES;
        [self _rescheduleCleanupTimer];
        [self cleanupDiskCache];
    }
    return self;
}

- (id)initWithName:(NSString *)name memoryCache:(NSCache *)memoryCache {
    if (!name.length) {
        [NSException raise:NSInvalidArgumentException format:@"Attemting to initialize DFCache without a name"];
    }
    NSString *storagePath = [[DFDiskCache cachesDirectoryPath] stringByAppendingPathComponent:name];
    DFDiskCache *storage = [[DFDiskCache alloc] initWithPath:storagePath error:nil];
    storage.capacity = 1024 * 1024 * 100; // 100 Mb
    storage.cleanupRate = 0.5f;
    return [self initWithDiskCache:storage memoryCache:memoryCache];
}

- (id)initWithName:(NSString *)name {
    NSCache *memoryCache = [NSCache new];
    memoryCache.totalCostLimit = 1024 * 1024 * 15; // 15 Mb
    memoryCache.name = name;
    return [self initWithName:name memoryCache:memoryCache];
}

#pragma mark - Read

- (void)cachedObjectForKey:(NSString *)key decode:(DFCacheDecodeBlock)decode cost:(DFCacheCostBlock)cost completion:(void (^)(id))completion {
    if (!completion) {
        return;
    }
    if (!key) {
        _dwarf_cache_callback(completion, nil);
        return;
    }
    id object = [_memoryCache objectForKey:key];
    if (object) {
        _dwarf_cache_callback(completion, object);
        return;
    }
    dispatch_async(_ioQueue, ^{
        NSData *data = [_diskCache dataForKey:key];
        if (!data) {
            _dwarf_cache_callback(completion, nil);
            return;
        }
        dispatch_async(_processingQueue, ^{
            id object = decode(data);
            [self storeObject:object forKey:key cost:cost];
            _dwarf_cache_callback(completion, object);
        });
    });
}

- (id)cachedObjectForKey:(NSString *)key decode:(DFCacheDecodeBlock)decode cost:(DFCacheCostBlock)cost {
    if (!key || !decode) {
        return nil;
    }
    id __block object = [_memoryCache objectForKey:key];
    if (object) {
        return object;
    }
    dispatch_sync(_ioQueue, ^{
        NSData *data = [_diskCache dataForKey:key];
        if (data) {
            object = decode(data);
            [self storeObject:object forKey:key cost:cost];
        }
    });
    return object;
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
    if (!object || !key.length) {
        return;
    }
    [_memoryCache setObject:object forKey:key cost:cost];
    if (!data && !encode) {
        return;
    }
    dispatch_async(_ioQueue, ^{
        [_diskCache setData:(data ?: encode(object)) forKey:key];
    });
}

- (void)storeObject:(id)object forKey:(NSString *)key cost:(DFCacheCostBlock)cost {
    if (!object || !key) {
        return;
    }
    NSUInteger objectCost = cost ? cost(object) : 0;
    [_memoryCache setObject:object forKey:key cost:objectCost];
}

#pragma mark - Remove

- (void)removeObjectsForKeys:(NSArray *)keys {
    if (!keys.count) {
        return;
    }
    for (NSString *key in keys) {
        [_memoryCache removeObjectForKey:key];
    }
    dispatch_async(_ioQueue, ^{
        for (NSString *key in keys) {
            [_diskCache removeDataForKey:key];
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
    dispatch_async(_ioQueue, ^{
        [_diskCache removeAllData];
    });
}

#pragma mark - Metadata

- (NSDictionary *)metadataForKey:(NSString *)key {
    if (!key) {
        return nil;
    }
    NSDictionary *__block metadata;
    dispatch_sync(_ioQueue, ^{
        NSURL *fileURL = [self.diskCache URLForKey:key];
        metadata = [fileURL extendedAttributeValueForKey:DFCacheAttributeMetadataKey error:nil];
    });
    return metadata;
}

- (void)setMetadata:(NSDictionary *)metadata forKey:(NSString *)key {
    if (!metadata || !key) {
        return;
    }
    dispatch_async(_ioQueue, ^{
        NSURL *fileURL = [self.diskCache URLForKey:key];
        [fileURL setExtendedAttributeValue:metadata forKey:DFCacheAttributeMetadataKey];
    });
}

- (void)setMetadataValues:(NSDictionary *)keyedValues forKey:(NSString *)key {
    if (!keyedValues.count || !key) {
        return;
    }
    dispatch_async(_ioQueue, ^{
        NSURL *fileURL = [self.diskCache URLForKey:key];
        NSDictionary *metadata = [fileURL extendedAttributeValueForKey:DFCacheAttributeMetadataKey error:nil];
        NSMutableDictionary *mutableMetadata = [[NSMutableDictionary alloc] initWithDictionary:metadata];
        [mutableMetadata addEntriesFromDictionary:keyedValues];
        [fileURL setExtendedAttributeValue:mutableMetadata forKey:DFCacheAttributeMetadataKey];
    });
}

- (void)removeMetadataForKey:(NSString *)key {
    if (!key) {
        return;
    }
    dispatch_async(_ioQueue, ^{
        NSURL *fileURL = [self.diskCache URLForKey:key];
        [fileURL removeExtendedAttributeForKey:DFCacheAttributeMetadataKey];
    });
}

#pragma mark - Cleanup

- (void)setCleanupTimerInterval:(NSTimeInterval)timeInterval {
    if (_cleanupTimeInterval != timeInterval) {
        _cleanupTimeInterval = timeInterval;
        [self _rescheduleCleanupTimer];
    }
}

- (void)setCleanupTimerEnabled:(BOOL)enabled {
    if (_cleanupTimerEnabled != enabled) {
        _cleanupTimerEnabled = enabled;
        [self _rescheduleCleanupTimer];
    }
}

- (void)_rescheduleCleanupTimer {
    [_cleanupTimer invalidate];
    if (!_cleanupTimerEnabled) {
        return;
    }
    DFCache *__weak weakSelf = self;
    _cleanupTimer = [DFCacheTimer scheduledTimerWithTimeInterval:_cleanupTimeInterval block:^{
        [weakSelf cleanupDiskCache];
    } userInfo:nil repeats:YES];
}

- (void)cleanupDiskCache {
    dispatch_async(_ioQueue, ^{
        [_diskCache cleanup];
    });
}

@end
