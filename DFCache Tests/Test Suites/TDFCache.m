// The MIT License (MIT)
//
// Copyright (c) 2014 Alexander Grebenyuk (github.com/kean).
//
// Permission is hereby granted, free of charge, to any person obtaining a copy
// of this software and associated documentation files (the "Software"), to deal
// in the Software without restriction, including without limitation the rights
// to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
// copies of the Software, and to permit persons to whom the Software is
// furnished to do so, subject to the following conditions:
//
// The above copyright notice and this permission notice shall be included in
// all copies or substantial portions of the Software.
//
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
// FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
// AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
// LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
// OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
// THE SOFTWARE.

#import "DFCache+Tests.h"
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
    
    NSString *cacheName = [NSString stringWithFormat:@"_dt_testcase_%lu", (unsigned long)_index];
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

- (void)testInitializationWithoutDiskCacheThrowsException {
    XCTAssertThrowsSpecificNamed([[DFCache alloc] initWithDiskCache:nil memoryCache:nil], NSException, NSInvalidArgumentException);
}

- (void)testInitializationWithoutNameThrowsException {
    XCTAssertThrowsSpecificNamed([[DFCache alloc] initWithName:nil memoryCache:nil], NSException, NSInvalidArgumentException);
    XCTAssertThrowsSpecificNamed([[DFCache alloc] initWithName:@"" memoryCache:nil], NSException, NSInvalidArgumentException);
    XCTAssertThrowsSpecificNamed([[DFCache alloc] initWithName:nil], NSException, NSInvalidArgumentException);
    XCTAssertThrowsSpecificNamed([[DFCache alloc] initWithName:@""], NSException, NSInvalidArgumentException);
}

#pragma mark - Write (custom encoders/decoders)

- (void)testWriteWithTransform {
    NSString *string = @"value1";
    NSString *key = @"key1";
    
    [_cache storeObject:string encode:^NSData *(id object) {
        return [((NSString *)object) dataUsingEncoding:NSUTF8StringEncoding];
    } forKey:key];
    
    XCTAssertNotNil([_cache.memoryCache objectForKey:key]);
    [_cache.memoryCache removeObjectForKey:key];
    
    NSString *cachedString = [_cache cachedObjectForKey:key decode:^id(NSData *data) {
        return [[NSString alloc] initWithBytes:[data bytes] length:[data length] encoding:NSUTF8StringEncoding];
    } cost:nil];
    XCTAssertEqualObjects(string, cachedString);
}

- (void)testWriteWithData {
    NSString *string = @"value1";
    NSString *key = @"key1";
    NSData *data = [string dataUsingEncoding:NSUTF8StringEncoding];
    
    [_cache storeObject:string data:data forKey:key];
    
    XCTAssertNotNil([_cache.memoryCache objectForKey:key]);
    [_cache.memoryCache removeObjectForKey:key];
    
    NSString *cachedString = [_cache cachedObjectForKey:key decode:^id(NSData *data) {
        return [[NSString alloc] initWithBytes:[data bytes] length:[data length] encoding:NSUTF8StringEncoding];
    } cost:nil];
    XCTAssertEqualObjects(string, cachedString);
}

- (void)testWriteWithDataDeprecated {
    NSString *string = @"value1";
    NSString *key = @"key1";
    NSData *data = [string dataUsingEncoding:NSUTF8StringEncoding];
    
    [_cache storeObject:string data:data forKey:key];
    
    XCTAssertNotNil([_cache.memoryCache objectForKey:key]);
    [_cache.memoryCache removeObjectForKey:key];
    
    NSString *cachedString = [_cache cachedObjectForKey:key decode:^id(NSData *data) {
        return [[NSString alloc] initWithBytes:[data bytes] length:[data length] encoding:NSUTF8StringEncoding];
    } cost:nil];
    XCTAssertEqualObjects(string, cachedString);
}

- (void)testWriteNoTransformNoData {
    NSString *string = @"test_string";
    NSString *key = @"key3";
    
    [_cache storeObject:string encode:nil forKey:key];
    
    XCTAssertNotNil([_cache.memoryCache objectForKey:key]);
    [_cache.memoryCache removeObjectForKey:key];
    
    NSString *cachedString = [_cache cachedObjectForKey:key decode:DFCacheDecodeNSCoding cost:nil];
    XCTAssertNil(cachedString);
}

#pragma mark - Write (predifined encoders/decoders)
 
- (void)testWriteJSON {
    NSDictionary *JSON = @{ @"key" : @"value" };
    NSString *key = @"key3";
    
    [_cache storeObject:JSON encode:DFCacheEncodeJSON forKey:key];

    BOOL __block isWaiting = YES;
    [_cache cachedObjectForKey:key decode:DFCacheDecodeJSON cost:nil completion:^(id object) {
        XCTAssertTrue([JSON[@"key"] isEqualToString:object[@"key"]]);
        isWaiting = NO;
    }];
    DWARF_TEST_WAIT_WHILE(isWaiting, 10.f);
}

- (void)testWriteNSCoding {
    NSString *string = @"test_string";
    NSString *key = @"key3";
    
    [_cache storeObject:string encode:DFCacheEncodeNSCoding forKey:key];
    
    XCTAssertNotNil([_cache.memoryCache objectForKey:key]);
    [_cache.memoryCache removeObjectForKey:key];
    
    NSString *cachedString = [_cache cachedObjectForKey:key decode:DFCacheDecodeNSCoding cost:nil];
    XCTAssertEqualObjects(string, cachedString);
}

#pragma mark - Read (No Cost)

- (void)testReadAsynchronouslyNoCostBlock {
    NSDictionary *JSON = @{ @"key" : @"value" };
    NSString *key = @"key3";
    
    [_cache storeObject:JSON encode:DFCacheEncodeJSON forKey:key];
    
    BOOL __block isWaiting = YES;
    [_cache cachedObjectForKey:key decode:DFCacheDecodeJSON completion:^(id object) {
        XCTAssertTrue([JSON[@"key"] isEqualToString:object[@"key"]]);
        isWaiting = NO;
    }];
    DWARF_TEST_WAIT_WHILE(isWaiting, 10.f);
}

- (void)testReadSynchrousltNoCost {
    NSString *string = @"test_string";
    NSString *key = @"key3";
    [_cache storeObject:string encode:DFCacheEncodeNSCoding forKey:key];
    XCTAssertNotNil([_cache.memoryCache objectForKey:key]);
    [_cache.memoryCache removeObjectForKey:key];
    
    NSString *cachedString = [_cache cachedObjectForKey:key decode:DFCacheDecodeNSCoding];
    XCTAssertEqualObjects(string, cachedString);
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
    
    [self _assertDoesntContainObjectsForKeys:@[removeKey]];
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
    [self _assertDoesntContainObjectsForKeys:removeKeys];
}

- (void)testRemoveAllObjects {
    NSDictionary *objects;
    [_cache storeStringsWithCount:5 strings:&objects];
    
    [_cache removeAllObjects];
    
    [self _assertDoesntContainObjectsForKeys:[objects allKeys]];
}

#pragma mark - Metadata Tests

- (void)testStoreObjectWithMetadata {
    NSString *value = @"Metadata text";
    NSString *key = @"key4";
    
    // 1.0. Store object with custom key-value in metadata.
    // ====================================================
    NSString *metaValue = @"meta_value";
    NSString *metaKey = @"meta_key";
    
    [_cache storeObject:value encode:DFCacheEncodeNSCoding forKey:key];
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

#pragma mark - Memory Pressure

#if (__IPHONE_OS_VERSION_MIN_REQUIRED)
- (void)testRespondsToMemoryWarning {
    [_cache.memoryCache setObject:@"object" forKey:@"key"];
    XCTAssertNotNil([_cache.memoryCache objectForKey:@"key"]);
    [[NSNotificationCenter defaultCenter] postNotificationName:UIApplicationDidReceiveMemoryWarningNotification object:nil userInfo:nil];
    XCTAssertNil([_cache.memoryCache objectForKey:@"key"]);
}
#endif

#pragma mark - Direct Data Access

- (void)testCachedDataForKeyAsynchronous {
    NSString *object = @"value";
    NSString *key = @"key";
    
    [_cache storeObject:object encode:DFCacheEncodeNSCoding forKey:key];
    
    BOOL __block isWaiting = YES;
    [_cache cachedDataForKey:key completion:^(NSData *data) {
        XCTAssertEqualObjects(object, DFCacheDecodeNSCoding(data));
        isWaiting = NO;
    }];
    
    DWARF_TEST_WAIT_WHILE(isWaiting, 10.f);
}

- (void)testCachedDataForKeySynchronous {
    NSString *object = @"value";
    NSString *key = @"key";
    
    [_cache storeObject:object encode:DFCacheEncodeNSCoding forKey:key];
    NSData *data = [_cache cachedDataForKey:key];
    XCTAssertEqualObjects(object, DFCacheDecodeNSCoding(data));
}

- (void)testStoreDataForKey {
    size_t dataSize = 10000;
    int *buffer = malloc(dataSize);
    NSData *data = [NSData dataWithBytesNoCopy:buffer length:dataSize];
    
    [_cache storeData:data forKey:@"key"];
    NSData *cachedData = [_cache cachedDataForKey:@"key"];
    XCTAssertTrue([data length] == [cachedData length]);
}

#pragma mark - Helpers

- (NSData *)_testDataWithSize:(unsigned long long)size {
    int *buffer = malloc(size);
    return [NSData dataWithBytesNoCopy:buffer length:size];
}

- (void)_assertContainsObjectsForKeys:(NSArray *)keys objects:(NSDictionary *)objects {
    for (NSString *key in keys) {
        {
            id object = [_cache cachedObjectForKey:key decode:DFCacheDecodeNSCoding cost:nil];
            XCTAssertNotNil(object, @"Disk cache: no object for key %@", key);
            XCTAssertEqualObjects(objects[key], object);
        }
    }
}

- (void)_assertDoesntContainObjectsForKeys:(NSArray *)keys {
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
