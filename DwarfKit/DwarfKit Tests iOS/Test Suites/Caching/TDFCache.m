/*
 The MIT License (MIT)
 
 Copyright (c) 2013 Alexander Grebenyuk (github.com/kean).
 
 Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:
 
 The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.
 
 THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
 */

#import "DFCache+Extended.h"
#import "DFCache+UIImage.h"
#import "DFCache.h"
#import "DFTesting.h"
#import "TDFCache.h"


@implementation TDFCache {
    DFCache *_cache;
}

- (void)setUp {
    [super setUp];
    
    static NSUInteger _index = 0;
    
    NSString *cacheName = [NSString stringWithFormat:@"_dt_testcase_%i", _index];
    _cache = [[DFCache alloc] initWithName:cacheName];
    _index++;
}


- (void)tearDown {
    [super tearDown];
    
    [_cache removeAllObjects];
    _cache = nil;
}

- (void)testInitialization {
    NSString *name = @"test_name";
    DFCache *cache = [[DFCache alloc] initWithName:name];
    STAssertNotNil(cache.memoryCache, NULL);
    STAssertNotNil(cache.diskCache, NULL);
    STAssertTrue([cache.memoryCache.name isEqualToString:name], NULL);
    
    STAssertThrows([[DFCache alloc] initWithName:@""], NULL);
    STAssertThrows([[DFCache alloc] initWithName:nil], NULL);
}

- (void)testWriteWithTransform {
    UIImage *value = [self _testImage];
    NSString *key = @"key1";
    
    [_cache storeObject:value forKey:key cost:0.f encode:^NSData *(id object) {
        return UIImageJPEGRepresentation(object, 1.0);
    }];
    
    STAssertNotNil([_cache.memoryCache objectForKey:key], NULL);
    [_cache.memoryCache removeObjectForKey:key];
    
    __block BOOL isWaiting = YES;
    [_cache cachedObjectForKey:key decode:^id(NSData *data) {
        return [UIImage imageWithData:data];
    } cost:nil completion:^(id object) {
        [self _assertImage:value isEqualImage:object];
        isWaiting = NO;
    }];

    DWARF_TEST_WAIT_WHILE(isWaiting, 10.f);
}

- (void)testWriteWithData {
    UIImage *value = [self _testImage];
    NSString *key = @"key1";
    NSData *data = UIImageJPEGRepresentation(value, 1.0);
    
    [_cache storeObject:value forKey:key cost:0.f data:data];
    
    STAssertNotNil([_cache.memoryCache objectForKey:key], NULL);
    [_cache.memoryCache removeObjectForKey:key];
    
    __block BOOL isWaiting = YES;
    [_cache cachedObjectForKey:key decode:^id(NSData *data) {
        return [UIImage imageWithData:data];
    } cost:nil completion:^(UIImage *object) {
        [self _assertImage:value isEqualImage:object];
        STAssertNotNil(object, nil);
        isWaiting = NO;
    }];
    DWARF_TEST_WAIT_WHILE(isWaiting, 10.f);
}

- (void)testWriteNoTransformNoData {
    NSString *value = @"test_string";
    NSString *key = @"key3";
    
    [_cache storeObject:value forKey:key cost:0.f encode:nil];
    
    STAssertNotNil([_cache.memoryCache objectForKey:key], NULL);
    [_cache.memoryCache removeObjectForKey:key];
    
    __block BOOL isWaiting = YES;
    [_cache cachedObjectForKey:key decode:^id(NSData *data) {
        return [NSKeyedUnarchiver unarchiveObjectWithData:data];
    } cost:nil completion:^(id object) {
        STAssertNil(object, nil);
        isWaiting = NO;
    }];
    DWARF_TEST_WAIT_WHILE(isWaiting, 10.f);
}

- (void)testWriteImageCaching {
    UIImage *value = [self _testImage];
    NSString *key = @"key2";
    
    [_cache storeImage:value imageData:nil forKey:key];
    
    STAssertNotNil([_cache.memoryCache objectForKey:key], NULL);
    
    __block BOOL isWaiting = YES;
    [_cache cachedImageForKey:key completion:^(UIImage *image) {
        [self _assertImage:value isEqualImage:image];
        isWaiting = NO;
    }];
    DWARF_TEST_WAIT_WHILE(isWaiting, 10.f);
}

- (void)testWriteJSON {
    NSDictionary *JSON = @{ @"key" : @"value" };
    NSString *key = @"key3";
    
    [_cache storeObject:JSON forKey:key cost:0.f encode:DFCacheEncodeJSON];

    __block BOOL isWaiting = YES;
    [_cache cachedObjectForKey:key decode:DFCacheDecodeJSON cost:nil completion:^(id object) {
        STAssertTrue([JSON[@"key"] isEqualToString:object[@"key"]], NULL);
        isWaiting = NO;
    }];
    DWARF_TEST_WAIT_WHILE(isWaiting, 10.f);
}

#pragma mark - Removal

- (void)testRemovalForSingleKey {
    NSDictionary *objects;
    NSArray *keys;
    
    [self _storeStringsInCache:_cache objects:&objects keys:&keys];
    
    NSString *removeKey = keys[2];
    
    NSMutableArray *remainingKeys = [NSMutableArray arrayWithArray:keys];
    [remainingKeys removeObject:removeKey];
    
    [_cache removeObjectForKey:removeKey];
    
    // Assertions
    // ==========
    [self _assertDoesntContainObjectsForKeys:@[removeKey] objects:objects];
    [self _assertContainsObjectsForKeys:remainingKeys objects:objects];
}

- (void)testRemovalForMultipleKeys {
    NSDictionary *objects;
    NSArray *keys;
    [self _storeStringsInCache:_cache objects:&objects keys:&keys];
    
    NSArray *removeKeys = @[ keys[0], keys[2], keys[3] ];
    NSArray *remainingKeys = @[ keys[1], keys[4] ];
    
    [_cache removeObjectsForKeys:removeKeys];
    
    // Assertions
    // ==========
    [self _assertContainsObjectsForKeys:remainingKeys objects:objects];
    [self _assertDoesntContainObjectsForKeys:removeKeys objects:objects];
}

- (void)testRemoveAllObjects {
    NSDictionary *objects;
    NSArray *keys;
    [self _storeStringsInCache:_cache objects:&objects keys:&keys];
    
    [_cache removeAllObjects];
    
    // Assertions
    // ==========
    [self _assertDoesntContainObjectsForKeys:keys objects:objects];
}

#pragma mark - Metadata Tests

- (void)testStoreObjectWithMetadata {
    NSString *value = @"Metadata text";
    NSString *key = @"key4";
    
    // 1.0. Store object with custom key-value in metadata.
    // ====================================================
    NSString *metaValue = @"meta_value";
    NSString *metaKey = @"meta_key";
    
    [_cache storeObject:value forKey:key cost:0 encode:DFCacheEncodeNSCoding];
    [_cache setMetadata:@{ metaKey : metaValue } forKey:key];
    
    // 1.1. Read metadata right after storing object.
    // ==============================================
    NSDictionary *metadata = [_cache metadataForKey:key];
    STAssertNotNil(metadata, nil);
    STAssertTrue([metadata[metaKey] isEqualToString:metaValue], nil);

    // 1.2. Update metadata.
    // =====================
    NSString *customValueMod = @"custom_value_mod";
    
    [_cache setMetadataValues:@{ metaKey : customValueMod } forKey:key];

    metadata = [_cache metadataForKey:key];
    STAssertNotNil(metadata, nil);
    STAssertTrue([metadata[metaKey] isEqualToString:customValueMod], nil);
}

#pragma mark - Extended Category

- (void)testCachedObjectsForKeys {
    NSDictionary *strings;
    NSArray *keys;
    [self _storeStringsInCache:_cache objects:&strings keys:&keys];
    
    __block BOOL isWaiting = YES;
    [_cache cachedObjectsForKeys:keys decode:DFCacheDecodeNSCoding cost:nil completion:^(NSDictionary *objects) {
        for (NSString *key in keys) {
            STAssertTrue([objects[key] isEqualToString:strings[key]], NULL);
        }
        isWaiting = NO;
    }];
    
    DWARF_TEST_WAIT_WHILE(isWaiting, 10.f);
}

- (void)testCachedObjectsForKeysFromDisk {
    NSDictionary *strings;
    NSArray *keys;
    _cache.memoryCache = nil;
    
    [self _storeStringsInCache:_cache objects:&strings keys:&keys];
    
    __block BOOL isWaiting = YES;
    [_cache cachedObjectsForKeys:keys decode:DFCacheDecodeNSCoding cost:nil completion:^(NSDictionary *objects) {
        for (NSString *key in keys) {
            STAssertTrue([objects[key] isEqualToString:strings[key]], NULL);
        }
        isWaiting = NO;
    }];
    
    DWARF_TEST_WAIT_WHILE(isWaiting, 10.f);
}

- (void)testCachedObjectForAnyKey {
    NSDictionary *strings;
    NSArray *keys;
    [self _storeStringsInCache:_cache objects:&strings keys:&keys];
    [_cache removeObjectForKey:keys[0]];
    
    __block BOOL isWaiting = YES;
    [_cache cachedObjectForAnyKey:keys decode:DFCacheDecodeNSCoding cost:nil completion:^(id object, NSString *key) {
        STAssertTrue([key isEqualToString:keys[1]], NULL);
        STAssertTrue([object isEqualToString:strings[keys[1]]], NULL);
        isWaiting = NO;
    }];

    DWARF_TEST_WAIT_WHILE(isWaiting, 10.f);
}

- (void)testCachedObjectForAnyKeyFromDisk {
    NSDictionary *strings;
    NSArray *keys;
     _cache.memoryCache = nil;
    
    [self _storeStringsInCache:_cache objects:&strings keys:&keys];
    [_cache removeObjectForKey:keys[0]];
    
    __block BOOL isWaiting = YES;
    [_cache cachedObjectForAnyKey:keys decode:DFCacheDecodeNSCoding cost:nil completion:^(id object, NSString *key) {
        STAssertTrue([key isEqualToString:keys[1]], NULL);
        STAssertTrue([object isEqualToString:strings[keys[1]]], NULL);
        isWaiting = NO;
    }];
    
    DWARF_TEST_WAIT_WHILE(isWaiting, 10.f);
}

#pragma mark - Helpers

- (UIImage *)_testImage {
    NSBundle *bundle = [NSBundle bundleForClass:[self class]];
    NSString *path = [bundle pathForResource:@"image" ofType:@"jpeg"];
    return [UIImage imageWithContentsOfFile:path];
}


- (void)_assertImage:(UIImage *)img1 isEqualImage:(UIImage *)img2 {
    STAssertNotNil(img1, nil);
    STAssertNotNil(img2, nil);
    STAssertTrue(img1.size.width * img1.scale ==
                 img2.size.width * img2.scale, nil);
    STAssertTrue(img1.size.height * img1.scale ==
                 img2.size.height * img2.scale, nil);
}

- (void)_storeStringsInCache:(DFCache *)cache objects:(NSDictionary **)objects keys:(NSArray **)keys {
    *objects =
    @{
      @"key1" : @"jf-230fj9efje9rjdsofp",
      @"key2" : @"20jfsoedfjsfew",
      @"key3" : @"0-2jkfewjfewope2k3p",
      @"key4" : @"fk20fk2ojk2eop23",
      @"key5" : @"dk2-021k20ek1 120 k0-1k0"
      };
    
    *keys = @[ @"key1", @"key2", @"key3", @"key4", @"key5" ];
    
    for (NSString *key in (*keys)) {
        [_cache storeObject:(*objects)[key] forKey:key cost:0 encode:DFCacheEncodeNSCoding];
    }
}

- (void)_assertContainsObjectsForKeys:(NSArray *)keys objects:(NSDictionary *)objects {
    for (NSString *key in keys) {
        {
            NSString *object = [_cache.memoryCache objectForKey:key];;
            STAssertNotNil(object, @"mem failure");
            STAssertEqualObjects(objects[key], object, @"mem failure");
        }
        
        {
            id object = [_cache cachedObjectForKey:key decode:DFCacheDecodeNSCoding cost:nil];
            STAssertNotNil(object, @"disk failure");
            STAssertEqualObjects(objects[key], object, @"disk failure");
        }
    }
}

- (void)_assertDoesntContainObjectsForKeys:(NSArray *)keys objects:(NSDictionary *)objects {
    for (NSString *key in keys) {
        {
            NSString *object = [_cache.memoryCache objectForKey:key];
            STAssertNil(object, @"mem failure");
        }
        
        {
            id object = [_cache cachedObjectForKey:key decode:DFCacheDecodeNSCoding cost:nil];
            STAssertNil(object, @"disk failure");
        }
    }
}

@end
