/*
 The MIT License (MIT)
 
 Copyright (c) 2013 Alexander Grebenyuk (github.com/kean).
 
 Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:
 
 The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.
 
 THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
 */

#import "DFCache+Tests.h"
#import "DFCache+UIImage.h"
#import "DFCache.h"
#import "DFTesting.h"
#import <XCTest/XCTest.h>


@interface TDFCache : XCTestCase

@end


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
    XCTAssertNotNil(cache.memoryCache);
    XCTAssertNotNil(cache.diskCache);
    XCTAssertTrue([cache.memoryCache.name isEqualToString:name]);
    
    XCTAssertThrows([[DFCache alloc] initWithName:@""]);
    XCTAssertThrows([[DFCache alloc] initWithName:nil]);
}

- (void)testWriteWithTransform {
    UIImage *value = [self _testImage];
    NSString *key = @"key1";
    
    [_cache storeObject:value forKey:key cost:0.f encode:^NSData *(id object) {
        return UIImageJPEGRepresentation(object, 1.0);
    }];
    
    XCTAssertNotNil([_cache.memoryCache objectForKey:key]);
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
    
    XCTAssertNotNil([_cache.memoryCache objectForKey:key]);
    [_cache.memoryCache removeObjectForKey:key];
    
    __block BOOL isWaiting = YES;
    [_cache cachedObjectForKey:key decode:^id(NSData *data) {
        return [UIImage imageWithData:data];
    } cost:nil completion:^(UIImage *object) {
        [self _assertImage:value isEqualImage:object];
        XCTAssertNotNil(object);
        isWaiting = NO;
    }];
    DWARF_TEST_WAIT_WHILE(isWaiting, 10.f);
}

- (void)testWriteNoTransformNoData {
    NSString *value = @"test_string";
    NSString *key = @"key3";
    
    [_cache storeObject:value forKey:key cost:0.f encode:nil];
    
    XCTAssertNotNil([_cache.memoryCache objectForKey:key]);
    [_cache.memoryCache removeObjectForKey:key];
    
    __block BOOL isWaiting = YES;
    [_cache cachedObjectForKey:key decode:^id(NSData *data) {
        return [NSKeyedUnarchiver unarchiveObjectWithData:data];
    } cost:nil completion:^(id object) {
        XCTAssertNil(object);
        isWaiting = NO;
    }];
    DWARF_TEST_WAIT_WHILE(isWaiting, 10.f);
}

- (void)testWriteImageCaching {
    UIImage *value = [self _testImage];
    NSString *key = @"key2";
    
    [_cache storeImage:value imageData:nil forKey:key];
    
    XCTAssertNotNil([_cache.memoryCache objectForKey:key]);
    
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
        XCTAssertTrue([JSON[@"key"] isEqualToString:object[@"key"]]);
        isWaiting = NO;
    }];
    DWARF_TEST_WAIT_WHILE(isWaiting, 10.f);
}

#pragma mark - Removal

- (void)testRemovalForSingleKey {
    NSDictionary *objects;
    [_cache storeStringsWithCount:5 strings:&objects];
    NSArray *keys = [objects allKeys];
    
    NSString *removeKey = keys[2];
    
    NSMutableArray *remainingKeys = [NSMutableArray arrayWithArray:keys];
    [remainingKeys removeObject:removeKey];
    
    [_cache removeObjectForKey:removeKey];
    
    [self _assertDoesntContainObjectsForKeys:@[removeKey] objects:objects];
    [self _assertContainsObjectsForKeys:remainingKeys objects:objects];
}

- (void)testRemovalForMultipleKeys {
    NSDictionary *objects;
    [_cache storeStringsWithCount:5 strings:&objects];
    NSArray *keys = [objects allKeys];
    
    NSArray *removeKeys = @[ keys[0], keys[2], keys[3] ];
    NSArray *remainingKeys = @[ keys[1], keys[4] ];
    
    [_cache removeObjectsForKeys:removeKeys];
    
    [self _assertContainsObjectsForKeys:remainingKeys objects:objects];
    [self _assertDoesntContainObjectsForKeys:removeKeys objects:objects];
}

- (void)testRemoveAllObjects {
    NSDictionary *objects;
    [_cache storeStringsWithCount:5 strings:&objects];
    
    [_cache removeAllObjects];
    
    [self _assertDoesntContainObjectsForKeys:[objects allKeys] objects:objects];
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
    XCTAssertNotNil(metadata);
    XCTAssertTrue([metadata[metaKey] isEqualToString:metaValue]);

    // 1.2. Update metadata.
    // =====================
    NSString *customValueMod = @"custom_value_mod";
    
    [_cache setMetadataValues:@{ metaKey : customValueMod } forKey:key];

    metadata = [_cache metadataForKey:key];
    XCTAssertNotNil(metadata);
    XCTAssertTrue([metadata[metaKey] isEqualToString:customValueMod]);
}

#pragma mark - Helpers

- (UIImage *)_testImage {
    NSBundle *bundle = [NSBundle bundleForClass:[self class]];
    NSString *path = [bundle pathForResource:@"image" ofType:@"jpeg"];
    return [UIImage imageWithContentsOfFile:path];
}


- (void)_assertImage:(UIImage *)img1 isEqualImage:(UIImage *)img2 {
    XCTAssertNotNil(img1);
    XCTAssertNotNil(img2);
    XCTAssertTrue(img1.size.width * img1.scale ==
                 img2.size.width * img2.scale);
    XCTAssertTrue(img1.size.height * img1.scale ==
                 img2.size.height * img2.scale);
}

- (void)_assertContainsObjectsForKeys:(NSArray *)keys objects:(NSDictionary *)objects {
    for (NSString *key in keys) {
        {
            NSString *object = [_cache.memoryCache objectForKey:key];;
            XCTAssertNotNil(object, @"Memory cache: no object for key %@", key);
            XCTAssertEqualObjects(objects[key], object);
        }
        
        {
            id object = [_cache cachedObjectForKey:key decode:DFCacheDecodeNSCoding cost:nil];
            XCTAssertNotNil(object, @"Disk cache: no object for key %@", key);
            XCTAssertEqualObjects(objects[key], object);
        }
    }
}

- (void)_assertDoesntContainObjectsForKeys:(NSArray *)keys objects:(NSDictionary *)objects {
    for (NSString *key in keys) {
        {
            NSString *object = [_cache.memoryCache objectForKey:key];
            XCTAssertNil(object, @"Memory cache: contains object for key %@", key);
        }
        
        {
            id object = [_cache cachedObjectForKey:key decode:DFCacheDecodeNSCoding cost:nil];
            XCTAssertNil(object, @"Disk cache: contains object for key %@", key);
        }
    }
}

@end
