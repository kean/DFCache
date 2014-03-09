/*
 The MIT License (MIT)
 
 Copyright (c) 2013 Alexander Grebenyuk (github.com/kean).
 
 Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:
 
 The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.
 
 THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
 */

#import "DFCache+Extensions.h"
#import "DFCachePrivate.h"

@implementation DFCache (Extensions)

- (void)cachedDataForKey:(NSString *)key completion:(void (^)(NSData *))completion {
    if (!completion) {
        return;
    }
    if (!key.length) {
        _dwarf_cache_callback(completion, nil);
        return;
    }
    dispatch_async(self.ioQueue, ^{
        NSData *data = [self.diskCache dataForKey:key];
        _dwarf_cache_callback(completion, data);
    });
}

- (NSData *)cachedDataForKey:(NSString *)key {
    if (!key.length) {
        return nil;
    }
    NSData *__block data;
    dispatch_sync(self.ioQueue, ^{
        data = [self.diskCache dataForKey:key];
    });
    return data;
}

- (void)storeData:(NSData *)data forKey:(NSString *)key {
    if (!data || !key.length) {
        return;
    }
    dispatch_async(self.ioQueue, ^{
        [self.diskCache setData:data forKey:key];
    });
}

- (void)cachedDataForKeys:(NSArray *)keys completion:(void (^)(NSDictionary *))completion {
    if (!completion) {
        return;
    }
    if (!keys.count) {
        _dwarf_cache_callback(completion, nil);
        return;
    }
    dispatch_async(self.ioQueue, ^{
        NSMutableDictionary *objects = [NSMutableDictionary new];
        for (NSString *key in keys) {
            NSData *data = [self.diskCache dataForKey:key];
            if (data) {
                objects[key] = data;
            }
        }
        _dwarf_cache_callback(completion, objects);
    });
}

- (void)cachedObjectsForKeys:(NSArray *)keys decode:(DFCacheDecodeBlock)decode cost:(DFCacheCostBlock)cost completion:(void (^)(NSDictionary *))completion {
    if (!completion) {
        return;
    }
    if (!keys.count) {
        _dwarf_cache_callback(completion, nil);
        return;
    }
    NSMutableArray *remainingKeys = [NSMutableArray arrayWithArray:keys];
    NSMutableDictionary *foundObjects = [NSMutableDictionary new];
    
    // Lookup objects into memory cache.
    for (NSString *key in keys) {
        id object = [self.memoryCache objectForKey:key];
        if (object) {
            foundObjects[key] = object;
            [remainingKeys removeObject:key];
        }
    }
    if (!remainingKeys.count) {
        _dwarf_cache_callback(completion, foundObjects);
        return;
    }
    
    // Lookup data for remaining keys into disk storage.
    dispatch_async(self.ioQueue, ^{
        NSMutableDictionary *foundData = [NSMutableDictionary new];
        for (NSString *key in remainingKeys) {
            NSData *data = [self.diskCache dataForKey:key];
            if (data) {
                foundData[key] = data;
            }
        }
        dispatch_async(self.processingQueue, ^{
            for (NSString *key in foundData) {
                NSData *data = foundData[key];
                id object = decode(data);
                if (object) {
                    [self storeObject:object forKey:key cost:cost];
                    foundObjects[key] = object;
                }
            }
            _dwarf_cache_callback(completion, foundObjects);
        });
    });
}

- (void)cachedObjectForAnyKey:(NSArray *)keys decode:(DFCacheDecodeBlock)decode cost:(DFCacheCostBlock)cost completion:(void (^)(id, NSString *))completion {
    if (!completion) {
        return;
    }
    if (!keys.count) {
        dispatch_async(dispatch_get_main_queue(), ^{
            completion(nil, nil);
        });
        return;
    }
    dispatch_async(self.ioQueue, ^{
        id foundObject;
        NSString *foundKey;
        for (NSString *key in keys) {
            id object = [self.memoryCache objectForKey:key];
            if (object) {
                foundObject = object;
                foundKey = key;
                break;
            }
            NSData *data = [self.diskCache dataForKey:key];
            if (!data) {
                continue;
            }
            object = decode(data);
            if (object) {
                foundObject = object;
                foundKey = key;
                [self storeObject:object forKey:key cost:cost];
                break;
            }
        }
        dispatch_async(dispatch_get_main_queue(), ^{
            completion(foundObject, foundKey);
        });
    });
}

@end
