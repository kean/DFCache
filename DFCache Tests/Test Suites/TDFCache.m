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

#pragma mark - Write (General)

- (void)testThatNSStringIsWrittenProvidingValueTransformer {
    /* Test that storeObject:valueTransformer:forKey: works if we provide a valid value transformer, object and key.
     */
    NSString *string = @"value1";
    NSString *key = @"key1";
    
    [_cache storeObject:string forKey:key valueTransformer:[DFValueTransformerNSCoding new]];
    
    NSString *cachedString = [_cache cachedObjectForKey:key valueTransformer:[DFValueTransformerNSCoding new]];
    XCTAssertEqualObjects(string, cachedString);
}

- (void)testWriteWithoutProvidingValueTransformer {
    /* Test that storeObject:valueTransformer:forKey: works if we provide do not provide a value transformer and when value transformer is retrieved from the value transformer factory.
     */
    
    NSString *string = @"value1";
    NSString *key = @"key1";
    
    XCTAssertTrue([[_cache.valueTransfomerFactory valueTransformerForValue:string] class] == [DFValueTransformerNSCoding class]);
    
    [_cache storeObject:string forKey:key valueTransformer:nil];
    
    NSString *cachedString = [_cache cachedObjectForKey:key valueTransformer:[DFValueTransformerNSCoding new]];
    XCTAssertEqualObjects(string, cachedString);
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
    
    [_cache storeObject:dummy forKey:key valueTransformer:nil data:data];
    
    TDFCacheUnsupportedDummy *cacheDummy = [_cache cachedObjectForKey:key valueTransformer:[TDFValueTransformerCacheUnsupportedDummy new]];
    XCTAssertEqualObjects(cacheDummy, dummy);
}

#pragma mark - Write (Exceptions)

- (void)testWriteWithoutKeyDoesntRaiseAnException {
    NSString *string = @"value1";
    [_cache storeObject:string forKey:nil valueTransformer:[DFValueTransformerNSCoding new]];
    NSString *cachedString = [_cache cachedObjectForKey:nil valueTransformer:[DFValueTransformerNSCoding new]];
    XCTAssertNil(cachedString);
}

- (void)testWriteWithoutObjectDoesntRaiseAnException {
    NSString *key = @"key1";
    [_cache storeObject:nil forKey:key valueTransformer:[DFValueTransformerNSCoding new]];
    NSString *cachedString = [_cache cachedObjectForKey:key valueTransformer:[DFValueTransformerNSCoding new]];
    XCTAssertNil(cachedString);
}

- (void)testWriteWithInvalidValueTransformerDoesntRaiseAnException {
    TDFCacheUnsupportedDummy *object = [TDFCacheUnsupportedDummy new];
    [_cache storeObject:object forKey:@"key" valueTransformer:[DFValueTransformerNSCoding new]];
    id cachedObject = [_cache cachedObjectForKey:@"key" valueTransformer:[DFValueTransformerNSCoding new]];
    XCTAssertNil(cachedObject);
}

#pragma mark - DFValueTransformerJSON

- (void)testWriteAndReadJSONByProvidingValueProvidersBothTimes {
    NSDictionary *JSON = @{ @"key" : @"value" };
    NSString *key = @"key3";
    
    [_cache storeObject:JSON forKey:key valueTransformer:[DFValueTransformerJSON new]];
    
    BOOL __block isWaiting = YES;
    [_cache cachedObjectForKey:key valueTransformer:[DFValueTransformerJSON new] completion:^(id object) {
        XCTAssertTrue([JSON[@"key"] isEqualToString:object[@"key"]]);
        isWaiting = NO;
    }];
    DWARF_TEST_WAIT_WHILE(isWaiting, 10.f);
}

- (void)testWriteAndReadJSONByProvidingValueProviderOnlyForWrite {
    NSDictionary *JSON = @{ @"key" : @"value" };
    NSString *key = @"key3";
    
    [_cache storeObject:JSON forKey:key valueTransformer:[DFValueTransformerJSON new]];
    
    BOOL __block isWaiting = YES;
    [_cache cachedObjectForKey:key completion:^(id object) {
        XCTAssertTrue([JSON[@"key"] isEqualToString:object[@"key"]]);
        isWaiting = NO;
    }];
    DWARF_TEST_WAIT_WHILE(isWaiting, 10.f);
}

#pragma mark - Read (Synchronous)

- (void)testReadWithValueTransformer {
    NSString *string = @"value1";
    NSString *key = @"key1";
    [_cache storeObject:string forKey:key valueTransformer:nil];
    NSString *cachedString = [_cache cachedObjectForKey:key valueTransformer:[DFValueTransformerNSCoding new]];
    XCTAssertEqualObjects(string, cachedString);
}

- (void)testReadWithoutValueTransformer {
    NSString *string = @"value1";
    NSString *key = @"key1";
    [_cache storeObject:string forKey:key valueTransformer:nil];
    NSString *cachedString = [_cache cachedObjectForKey:key valueTransformer:nil];
    XCTAssertEqualObjects(string, cachedString);
    
    cachedString = [_cache cachedObjectForKey:key];
    XCTAssertEqualObjects(string, cachedString);
}

- (void)testReadWithInvalidValueTransformerDoesntRaiseException {
    NSString *string = @"value1";
    NSString *key = @"key1";
    [_cache storeObject:string forKey:key valueTransformer:nil];
    id cachedObject = [_cache cachedObjectForKey:key valueTransformer:[DFValueTransformerJSON new]];
    XCTAssertNil(cachedObject);
}

#pragma mark - Read (Asynchronous)

- (void)testReadAsyncWithValueTransformer {
    NSString *string = @"value1";
    NSString *key = @"key1";
    [_cache storeObject:string forKey:key];
    
    BOOL __block isWaiting = YES;
    [_cache cachedObjectForKey:key valueTransformer:[DFValueTransformerNSCoding new] completion:^(id object) {
        XCTAssertTrue([string isEqualToString:object]);
        isWaiting = NO;
    }];
    DWARF_TEST_WAIT_WHILE(isWaiting, 10.f);
}

- (void)testAsyncReadWithoutValueTransformer {
    NSString *string = @"value1";
    NSString *key = @"key1";
    [_cache storeObject:string forKey:key valueTransformer:nil];
    
    BOOL __block isWaiting = YES;
    [_cache cachedObjectForKey:key valueTransformer:nil completion:^(id object) {
        XCTAssertTrue([string isEqualToString:object]);
        isWaiting = NO;
    }];
    DWARF_TEST_WAIT_WHILE(isWaiting, 10.f);
    
    BOOL __block isWaiting2 = YES;
    [_cache cachedObjectForKey:key completion:^(id object) {
        XCTAssertTrue([string isEqualToString:object]);
        isWaiting2 = NO;
    }];
    DWARF_TEST_WAIT_WHILE(isWaiting2, 10.f);
}

- (void)testReadAsyncWithInvalidValueTransformerDoesntRaiseException {
    NSString *string = @"value1";
    NSString *key = @"key1";
    [_cache storeObject:string forKey:key valueTransformer:nil];
    
    BOOL __block isWaiting = YES;
    [_cache cachedObjectForKey:key valueTransformer:[DFValueTransformerJSON new] completion:^(id object) {
        XCTAssertNil(object);
        isWaiting = NO;
    }];
    DWARF_TEST_WAIT_WHILE(isWaiting, 10.f);
}

#pragma mark - Memory Cache

- (void)testMemoryCache {
    DFCache *cache = [self _createCacheForMemoryCacheTesting];
    
    NSString *string = @"value1";
    NSString *key = @"key1";
    [cache storeObject:string forKey:key valueTransformer:nil];
    
    XCTAssertEqualObjects(string, [cache.memoryCache objectForKey:key]);
}

- (void)testThatReadMethodsUseMemoryCache {
    DFCache *cache = [self _createCacheForMemoryCacheTesting];
    
    TDFCacheUnsupportedDummy *dummy = [TDFCacheUnsupportedDummy new];
    NSString *key = @"key1";
    [cache storeObject:dummy forKey:key valueTransformer:nil];

    XCTAssertEqualObjects(dummy, [cache.memoryCache objectForKey:key]);

    TDFCacheUnsupportedDummy *cacheDummy = [cache cachedObjectForKey:key valueTransformer:nil];
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
    
    BOOL __block isWaiting = YES;
    [_cache cachedDataForKey:key completion:^(NSData *data) {
        DFValueTransformerNSCoding *transformer = [DFValueTransformerNSCoding new];
        XCTAssertEqualObjects(object, [transformer reverseTransfomedValue:data]);
        isWaiting = NO;
    }];
    
    DWARF_TEST_WAIT_WHILE(isWaiting, 10.f);
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
