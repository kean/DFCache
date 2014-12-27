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
    _cache = [[DFCache alloc] initWithName:cacheName memoryCache:nil];
    _index++;
}

- (void)tearDown {
    [super tearDown];
    
    [_cache removeAllObjects];
    _cache = nil;
}

- (void)testInitialization {
    NSString *name = @"test_init_01";
    DFCache *cache = [[DFCache alloc] initWithName:name];
    XCTAssertNotNil(cache.memoryCache);
    XCTAssertNotNil(cache.diskCache);
    XCTAssertTrue([cache.memoryCache.name isEqualToString:name]);
    
    XCTAssertThrows([[DFCache alloc] initWithName:@""]);
    XCTAssertThrows([[DFCache alloc] initWithName:nil]);
}

- (void)testInitializationValueTransformerFactoryDependencyInjectors {
    DFCache *cache1 = [[DFCache alloc] initWithName: @"test_init_02"];
    XCTAssertEqualObjects(cache1.valueTransfomerFactory, [DFValueTransformerFactory defaultFactory]);
    
    DFCache *cache2 = [[DFCache alloc] initWithDiskCache:[[DFDiskCache alloc] initWithName:@"test_init_02"] memoryCache:nil];
    XCTAssertEqualObjects(cache2.valueTransfomerFactory, [DFValueTransformerFactory defaultFactory]);
}

- (void)testInitializationWithoutDiskCache {
    DFCache *cache = [[DFCache alloc] initWithDiskCache:nil memoryCache:nil];
    [cache cleanupDiskCache];
    [cache removeAllObjects];
    [cache storeObject:@"object" forKey:@"key"];
    XCTAssertNil([cache cachedObjectForKey:@"key"]);
}

- (void)testInitializationWithoutNameThrowsException {
    XCTAssertThrowsSpecificNamed([[DFCache alloc] initWithName:nil memoryCache:nil], NSException, NSInvalidArgumentException);
    XCTAssertThrowsSpecificNamed([[DFCache alloc] initWithName:@"" memoryCache:nil], NSException, NSInvalidArgumentException);
    XCTAssertThrowsSpecificNamed([[DFCache alloc] initWithName:nil], NSException, NSInvalidArgumentException);
    XCTAssertThrowsSpecificNamed([[DFCache alloc] initWithName:@""], NSException, NSInvalidArgumentException);
}

#pragma mark - Write  & Read (General)

- (void)testWrite {
    NSString *string = @"value1";
    NSString *key = @"key1";
    
    XCTAssertEqualObjects([_cache.valueTransfomerFactory valueTransformerNameForValue:string], DFValueTransformerNSCodingName);
    
    [_cache storeObject:string forKey:key];
    
    XCTAssertEqualObjects(string, [_cache cachedObjectForKey:key]);
}

#pragma mark - Write (Unsupported Objects)

- (void)testDummy {
    TDFCacheUnsupportedDummy *dummy1 = [TDFCacheUnsupportedDummy new];
    TDFCacheUnsupportedDummy *dummy2 = [TDFCacheUnsupportedDummy new];
    XCTAssertNotEqualObjects(dummy1, dummy2);
    XCTAssertEqualObjects(dummy1, dummy1);
    NSData *data = [dummy1 dataRepresentation];
    TDFCacheUnsupportedDummy *dummy3 = [[TDFCacheUnsupportedDummy alloc] initWithData:data];
    XCTAssertEqualObjects(dummy1, dummy3);
}

- (void)testWriteUnsupportedObject {
    TDFCacheUnsupportedDummy *dummy = [TDFCacheUnsupportedDummy new];
    NSString *key = @"key3";
    
    [_cache storeObject:dummy forKey:key];
    
    TDFCacheUnsupportedDummy *cachedObject = [_cache cachedObjectForKey:key];
    XCTAssertNil(cachedObject);
}

- (void)testWriteUnsupportedObjectWithData {
    TDFCacheUnsupportedDummy *dummy = [TDFCacheUnsupportedDummy new];
    NSString *key = @"key1";
    NSData *data = [dummy dataRepresentation];
    [_cache setAllowsImageDecompression:NO];
    [_cache storeObject:dummy forKey:key data:data];
    
    XCTAssertNil([_cache cachedObjectForKey:key]);
    XCTAssertNotNil([_cache cachedDataForKey:key]);
}

#pragma mark - Write (Exceptions)

- (void)testWriteWithoutKeyDoesntRaiseAnException {
    NSString *string = @"value1";
    [_cache storeObject:string forKey:nil];
    XCTAssertNil([_cache cachedObjectForKey:nil]);
}

- (void)testWriteWithoutObjectDoesntRaiseAnException {
    NSString *key = @"key1";
    [_cache storeObject:nil forKey:key];
    XCTAssertNil([_cache cachedObjectForKey:key]);
}

#pragma mark - DFValueTransformerJSON

- (void)testDFValueTransformerJSON {
    NSDictionary *JSON = @{ @"key" : @"value" };
    id<DFValueTransforming> valueTransformer = [DFValueTransformerJSON new];
    NSData *data = [valueTransformer transformedValue:JSON];
    NSDictionary *reversedJSON = [valueTransformer reverseTransfomedValue:data];
    XCTAssertEqualObjects(JSON, reversedJSON);
}

#pragma mark - Read (Asynchronous)

- (void)testReadAsyncWithValueTransformer {
    NSString *string = @"value1";
    NSString *key = @"key1";
    [_cache storeObject:string forKey:key];
    
    XCTestExpectation *expectation = [self expectationWithDescription:@"read"];
    
    [_cache cachedObjectForKey:key completion:^(id object) {
        XCTAssertTrue([string isEqualToString:object]);
        [expectation fulfill];
    }];
    
    [self waitForExpectationsWithTimeout:3.0 handler:nil];
}

- (void)testReadAsyncDoesntCrashWhenCalledWithoutCompletionBlock {
    NSString *string = @"value1";
    NSString *key = @"key1";
    [_cache storeObject:string forKey:key];
    [_cache cachedObjectForKey:key completion:nil];
    
    // Make sure that previous cash lookup finished executing
    XCTestExpectation *expectation = [self expectationWithDescription:@"read"];
    [_cache cachedObjectForKey:key completion:^(id object) {
        XCTAssertNotNil(object);
        [expectation fulfill];
    }];
    [self waitForExpectationsWithTimeout:3.0 handler:nil];
}

#pragma mark - Memory Cache

- (void)testMemoryCache {
    DFCache *cache = [self _createCacheForMemoryCacheTesting];
    
    NSString *string = @"value1";
    NSString *key = @"key1";
    [cache storeObject:string forKey:key];
    
    XCTAssertEqualObjects(string, [cache.memoryCache objectForKey:key]);
}

- (void)testThatReadMethodsUseMemoryCache {
    DFCache *cache = [self _createCacheForMemoryCacheTesting];
    
    TDFCacheUnsupportedDummy *dummy = [TDFCacheUnsupportedDummy new];
    NSString *key = @"key1";
    [cache storeObject:dummy forKey:key];

    XCTAssertEqualObjects(dummy, [cache.memoryCache objectForKey:key]);

    TDFCacheUnsupportedDummy *cacheDummy = [cache cachedObjectForKey:key];
    XCTAssertEqualObjects(cacheDummy, dummy);
}

- (DFCache *)_createCacheForMemoryCacheTesting {
    NSString *name = [[NSUUID UUID] UUIDString];
    DFDiskCache *diskCache = [[DFDiskCache alloc] initWithName:name];
    return [[DFCache alloc] initWithDiskCache:diskCache memoryCache:[NSCache new]];
}

#if (__IPHONE_OS_VERSION_MIN_REQUIRED)
- (void)testRespondsToMemoryWarning {
    DFCache *cache = [self _createCacheForMemoryCacheTesting];
    [cache.memoryCache setObject:@"object" forKey:@"key"];
    XCTAssertNotNil([cache.memoryCache objectForKey:@"key"]);
    [[NSNotificationCenter defaultCenter] postNotificationName:UIApplicationDidReceiveMemoryWarningNotification object:nil userInfo:nil];
    XCTAssertNil([cache.memoryCache objectForKey:@"key"]);
}
#endif

#pragma mark - Remove

- (void)testRemovalForSingleKey {
    DFCache *cache = [self _createCacheForMemoryCacheTesting];
    
    NSDictionary *objects;
    [cache storeStringsWithCount:5 strings:&objects];
    NSArray *keys = [objects allKeys];
    
    NSString *removeKey = keys[2];
    
    NSMutableArray *remainingKeys = [NSMutableArray arrayWithArray:keys];
    [remainingKeys removeObject:removeKey];
    
    [cache removeObjectForKey:removeKey];
    
    for (NSString *key in @[removeKey]) {
        NSString *object = [cache.memoryCache objectForKey:key];
        XCTAssertNil(object, @"Memory cache: contains object for key %@", key);
        XCTAssertNil([cache cachedObjectForKey:key], @"Disk cache: contains object for key %@", key);
    }
    
    for (NSString *key in remainingKeys) {
        id object = [cache cachedObjectForKey:key];
        XCTAssertNotNil(object, @"Disk cache: no object for key %@", key);
        XCTAssertEqualObjects(objects[key], object);
    }
}

- (void)testRemovalForMultipleKeys {
    DFCache *cache = [self _createCacheForMemoryCacheTesting];
    
    NSDictionary *objects;
    [cache storeStringsWithCount:5 strings:&objects];
    NSArray *keys = [objects allKeys];
    
    NSArray *removeKeys = @[ keys[0], keys[2], keys[3] ];
    NSArray *remainingKeys = @[ keys[1], keys[4] ];
    
    [cache removeObjectsForKeys:removeKeys];
    
    for (NSString *key in remainingKeys) {
        id object = [cache cachedObjectForKey:key];
        XCTAssertNotNil(object, @"Disk cache: no object for key %@", key);
        XCTAssertEqualObjects(objects[key], object);
    }
    
    for (NSString *key in removeKeys) {
        NSString *object = [cache.memoryCache objectForKey:key];
        XCTAssertNil(object, @"Memory cache: contains object for key %@", key);
        XCTAssertNil([cache cachedObjectForKey:key], @"Disk cache: contains object for key %@", key);
    }
}

- (void)testRemoveAllObjects {
    DFCache *cache = [self _createCacheForMemoryCacheTesting];
    
    NSDictionary *objects;
    [cache storeStringsWithCount:5 strings:&objects];
    
    [cache removeAllObjects];
    
    for (NSString *key in [objects allKeys]) {
        NSString *object = [cache.memoryCache objectForKey:key];
        XCTAssertNil(object, @"Memory cache: contains object for key %@", key);
        XCTAssertNil([cache cachedObjectForKey:key], @"Disk cache: contains object for key %@", key);
    }
}

#pragma mark - Metadata Tests

- (void)testStoreObjectWithMetadata {
    NSString *value = @"Metadata text";
    NSString *key = @"key4";
    
    // 1.0. Store object with custom key-value in metadata.
    // ====================================================
    NSString *metaValue = @"meta_value";
    NSString *metaKey = @"meta_key";
    
    [_cache storeObject:value  forKey:key];
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

#pragma mark - Data

- (void)testCachedDataForKeyAsynchronous {
    NSString *object = @"value";
    NSString *key = @"key";
    
    [_cache storeObject:object forKey:key];
    
    XCTestExpectation *expectation = [self expectationWithDescription:@"read"];
    [_cache cachedDataForKey:key completion:^(NSData *data) {
        DFValueTransformerNSCoding *transformer = [DFValueTransformerNSCoding new];
        XCTAssertEqualObjects(object, [transformer reverseTransfomedValue:data]);
        [expectation fulfill];
    }];
    [self waitForExpectationsWithTimeout:3.0 handler:nil];
}

- (void)testCachedDataForKeySynchronous {
    NSString *object = @"value";
    NSString *key = @"key";
    
    [_cache storeObject:object forKey:key];
    NSData *data = [_cache cachedDataForKey:key];
    DFValueTransformerNSCoding *transformer = [DFValueTransformerNSCoding new];
    XCTAssertEqualObjects(object,[transformer reverseTransfomedValue:data]);
}

- (void)testStoreDataForKey {
    size_t dataSize = 10000;
    int *buffer = malloc(dataSize);
    NSData *data = [NSData dataWithBytesNoCopy:buffer length:dataSize];
    
    [_cache storeData:data forKey:@"key"];
    NSData *cachedData = [_cache cachedDataForKey:@"key"];
    XCTAssertTrue([data length] == [cachedData length]);
}

@end
