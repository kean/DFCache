/*
 The MIT License (MIT)
 
 Copyright (c) 2013 Alexander Grebenyuk (github.com/kean).
 
 Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:
 
 The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.
 
 THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
 */

#import "DFCache.h"
#import "DFOptions.h"
#import "DFTesting.h"
#import "TDFCacheTests.h"


@implementation TDFCacheTests {
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

#pragma mark - Basics

- (void)testNameAndDefaults {
    NSString *name = @"test_name";
    DFCache *cache = [[DFCache alloc] initWithName:name];
    STAssertTrue([cache.name isEqualToString:name], nil);
    STAssertTrue([cache.memoryCache.name isEqualToString:name], nil);
    STAssertTrue(cache.settings.filesExpirationPeriod == 60 * 60 * 24 * 7 * 4, nil);
    STAssertTrue(cache.settings.diskCacheCapacity == 1048576 * 100, nil);
}

#pragma mark - Write and Read Tests

- (void)testWriteWithTransform {
    UIImage *value = [self _testImage];
    NSString *key = @"key1";
    
    [_cache storeObject:value forKey:key data:nil transform:^NSData *(id object) {
        return UIImageJPEGRepresentation(object, 1.0);
    }];
    
    STAssertTrue([_cache objectForKey:key] == value, nil);
    
    __block BOOL isWaiting = YES;
    [_cache objectForKey:key queue:NULL transform:^id(NSData *data) {
        return [UIImage imageWithData:data];
    } completion:^(UIImage *object) {
        [self _assertImage:value isEqualImage:object];
        isWaiting = NO;
    }];
    DWARF_TEST_WAIT_WHILE(isWaiting, 10.f);
}


- (void)testWriteWithData {
    UIImage *value = [self _testImage];
    NSString *key = @"key1";
    NSData *data = UIImageJPEGRepresentation(value, 1.0);
    
    [_cache storeObject:value forKey:key data:data transform:nil];
    
    STAssertTrue([_cache objectForKey:key] == value, nil);
    
    __block BOOL isWaiting = YES;
    [_cache objectForKey:key queue:NULL transform:^id(NSData *data) {
        return [UIImage imageWithData:data];
    } completion:^(UIImage *object) {
        [self _assertImage:value isEqualImage:object];
        STAssertNotNil(object, nil);
        isWaiting = NO;
    }];
    DWARF_TEST_WAIT_WHILE(isWaiting, 10.f);
}


- (void)testWriteNoTransformNoData {
    NSString *value = @"test_string";
    NSString *key = @"key3";
    
    [_cache storeObject:value forKey:key data:nil transform:nil];
    
    STAssertTrue([_cache objectForKey:key] == value, nil);
    
    __block BOOL isWaiting = YES;
    [_cache objectForKey:key queue:NULL transform:^id(NSData *data) {
        return [NSKeyedUnarchiver unarchiveObjectWithData:data];
    } completion:^(id object) {
        STAssertNil(object, nil);
        isWaiting = NO;
    }];
    DWARF_TEST_WAIT_WHILE(isWaiting, 10.f);
}


- (void)testWriteImageCaching {
    UIImage *value = [self _testImage];
    NSString *key = @"key2";
    
    [_cache storeImage:value imageData:nil forKey:key];
    
    STAssertTrue([_cache imageForKey:key] == value, nil);
    
    __block BOOL isWaiting = YES;
    [_cache imageForKey:key queue:NULL completion:^(UIImage *object) {
        [self _assertImage:value isEqualImage:object];
        isWaiting = NO;
    }];
    DWARF_TEST_WAIT_WHILE(isWaiting, 10.f);
}


- (void)testWriteNSCoding {
    NSString *text = @"Test";
    NSString *key = @"key3";
    
    [_cache storeCodingObject:text metadata:nil cost:0.f forKey:key];
    
    __block BOOL isWaiting = YES;
    [_cache codingObjectForKey:key queue:NULL completion:^(id  object) {
        STAssertTrue([text isEqualToString:object], nil);
        isWaiting = NO;
    }];
    DWARF_TEST_WAIT_WHILE(isWaiting, 10.f);
}


- (void)testReadExpiredEntry {
    NSString *object = @"d2fl3-2f";
    NSString *key = @"key";
    NSDictionary *metadata = @{ DFCacheMetaExpirationDateKey : [NSDate dateWithTimeIntervalSinceNow:-10.f] };
    
    [_cache storeCodingObject:object metadata:metadata cost:0.f forKey:key];
    
    __block BOOL isWaiting = YES;
    [_cache codingObjectForKey:key queue:NULL completion:^(id object) {
        STAssertNil(object, nil);
        isWaiting = NO;
    }];
    DWARF_TEST_WAIT_WHILE(isWaiting, 10.f);
}

#pragma mark - Concurrency

- (void)testCallbackOnBackgroundThread {
    NSDictionary *objects;
    NSArray *keys;
    [self _storeStringsInCache:_cache objects:&objects keys:&keys];
    
    __block NSUInteger semaphore = 2;
    
    dispatch_queue_t queue = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0);
    [_cache codingObjectForKey:keys[0] queue:queue completion:^(id object) {
        STAssertTrue(![NSThread isMainThread], nil);
        semaphore--;
    }];
    
    [_cache codingObjectForKey:keys[1] queue:dispatch_get_main_queue() completion:^(id object) {
        STAssertTrue([NSThread isMainThread], nil);
        semaphore--;
    }];
    
    DWARF_TEST_WAIT_SEMAPHORE(semaphore, 10.f);
}


- (void)testConcurrencyStability {
    DFCache *cache = [[DFCache alloc] initWithName:@"concurrencty test"];
    
    NSString *(^randomKey)(void) = ^{
        return [NSString stringWithFormat:@"key_%i", arc4random() % 100];
    };
    
    NSString *(^randomString)(void) = ^{
        size_t length = 20;
        char data[length];
        for (int x = 0; x < length; x++) {
            data[x] = (char)('A' + arc4random_uniform(26));
        }
        return [[NSString alloc] initWithBytes:data length:length encoding:NSUTF8StringEncoding];
    };
    
    dispatch_queue_t (^randomQueue)(void) = ^{
        NSUInteger idx = arc4random() % 2;
        switch (idx) {
            case 0: return dispatch_get_main_queue(); break; 
            case 1: return dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0); break;
            default: return dispatch_get_main_queue(); break;
        }
    };
    
    NSMutableArray *actions = [NSMutableArray new];
    
    void (^actionWrite)(void) = ^{
        NSString *key = randomKey();
        NSString *string = randomString();
        [cache storeCodingObject:string metadata:nil cost:0.f forKey:key];
    };
    
    void (^actionRead)(void) = ^{
        [cache codingObjectForKey:randomKey() queue:randomQueue() completion:^(id object) {
            // Do nothing
        }];
    };
    
    void (^actionRemove)(void) = ^{
        [cache removeObjectForKey:randomKey()];
    };
    
    void (^actionCleanup)(void) = ^{
        [cache cleanupDiskCache];
    };
    
    [actions addObject:[actionWrite copy]];
    [actions addObject:[actionRead copy]];
    [actions addObject:[actionRemove copy]];
    [actions addObject:[actionCleanup copy]];
     
    NSUInteger iterationCount = 2000;
    
    for (NSUInteger i = 0; i < iterationCount; i++) {
        NSUInteger actionIndex = arc4random() % [actions count];
        dispatch_async(randomQueue(), actions[actionIndex]);
    }
    
    // Wait so that concurrency test won't interfere with other tests.
    NSDate *runUntilDate = [NSDate dateWithTimeIntervalSinceNow:4.f];
    [[NSRunLoop currentRunLoop] runUntilDate:runUntilDate];
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
    NSUInteger semaphore = [keys count];
    [self _assertDoesntContainObjectsForKeys:@[removeKey] objects:objects semaphore:&semaphore];
    [self _assertContainsObjectsForKeys:remainingKeys objects:objects semaphore:&semaphore];
    DWARF_TEST_WAIT_SEMAPHORE(semaphore, 10.f);
}


- (void)testRemovalForSingleKeyMemoryOnly {
    NSDictionary *objects;
    NSArray *keys;
    
    [self _storeStringsInCache:_cache objects:&objects keys:&keys];
    
    NSString *removeKey = keys[2];
    
    NSMutableArray *remainingKeys = [NSMutableArray arrayWithArray:keys];
    [remainingKeys removeObject:removeKey];
    
    [_cache removeObjectForKey:removeKey options:DFCacheRemoveFromMemory];
    
    // Assertions
    // ==========
    NSUInteger semaphore = [keys count];
    [self _assertContainsObjectsForKeys:remainingKeys objects:objects semaphore:&semaphore];
    [self _assertDoesntContainObjectsForKeys:@[removeKey] objects:objects semaphore:&semaphore options:DTEntrySourceMemory];
    [self _assertContainsObjectsForKeys:@[removeKey] objects:objects semaphore:&semaphore options:DTEntrySourceDisk];
    DWARF_TEST_WAIT_SEMAPHORE(semaphore, 20.f);
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
    NSUInteger semaphore = [keys count];
    [self _assertContainsObjectsForKeys:remainingKeys objects:objects semaphore:&semaphore];
    [self _assertDoesntContainObjectsForKeys:removeKeys objects:objects semaphore:&semaphore];
    DWARF_TEST_WAIT_SEMAPHORE(semaphore, 20.f);
}



- (void)testRemoveAllObjects {
    NSDictionary *objects;
    NSArray *keys;
    [self _storeStringsInCache:_cache objects:&objects keys:&keys];
    
    [_cache removeAllObjects];
    
    // Assertions
    // ==========
    NSUInteger semaphore = [keys count];
    [self _assertDoesntContainObjectsForKeys:keys objects:objects semaphore:&semaphore];
    DWARF_TEST_WAIT_SEMAPHORE(semaphore, 20.f);
}


- (void)testRemoveAllObjectsFromDiskOnly {
    NSDictionary *objects;
    NSArray *keys;
    [self _storeStringsInCache:_cache objects:&objects keys:&keys];
    
    [_cache removeAllObjects:DFCacheRemoveFromDisk];
    
    NSUInteger semaphore = [keys count];
    [self _assertDoesntContainObjectsForKeys:keys objects:objects semaphore:&semaphore options:DTEntrySourceDisk];
    [self _assertContainsObjectsForKeys:keys objects:objects semaphore:&semaphore options:DTEntrySourceMemory];
    DWARF_TEST_WAIT_SEMAPHORE(semaphore, 20.f);
}

#pragma mark - Metadata Tests

- (void)testStoreObjectWithMetadata {
    NSString *value = @"Metadata text";
    NSString *key = @"key4";
    
    // 1.0. Store object with custom key-value in metadata.
    // ====================================================
    NSString *customValue = @"custom_value";
    NSString *customKey = @"custom_key";
    
    [_cache storeCodingObject:value
                     metadata:@{ customKey : customValue }
                         cost:0.f
                       forKey:key];
    
    // 1.1. Read metadata right after storing object.
    // ==============================================
    NSDictionary *metadata = [_cache metadataForKey:key];
    STAssertNotNil(metadata, nil);
    STAssertTrue([metadata[customKey] isEqualToString:customValue], nil);
    
    NSString *filename = metadata[DFCacheMetaFileNameKey];
    NSDate *creationDate = metadata[DFCacheMetaCreationDateKey];
    NSDate *lastAccessDate = metadata[DFCacheMetaAccessDateKey];
    
    // 1.2. Update metadata.
    // =====================
    NSString *customValueMod = @"custom_value_mod";
    
    [_cache setMetadataValues:@{ customKey : customValueMod } forKey:key];
    
    metadata = [_cache metadataForKey:key];
    STAssertNotNil(metadata, nil);
    STAssertTrue([metadata[customKey] isEqualToString:customValueMod], nil);
    
    // 2. Test metadata persistence.
    // =============================
    sleep(4); // Simulate delay so that all I/O can be finished.
    
    NSString *cacheName = _cache.name;
    _cache = nil;
    _cache = [[DFCache alloc] initWithName:cacheName];
    
    metadata = [_cache metadataForKey:key];
    STAssertNotNil(metadata, nil);
    STAssertTrue([customValueMod isEqualToString:metadata[customKey]], nil);
    STAssertTrue([metadata[DFCacheMetaFileNameKey] isEqualToString:filename], nil);
    
    {
        NSString *desc1 = [metadata[DFCacheMetaCreationDateKey] description];
        NSString *desc2 = [creationDate description];
        STAssertTrue([desc1 isEqualToString:desc2], nil);
    }
    
    {
        NSString *desc1 = [metadata[DFCacheMetaAccessDateKey] description];
        NSString *desc2 = [lastAccessDate description];
        STAssertTrue([desc1 isEqualToString:desc2], nil);
    }
}

#pragma mark - Disk Clean Tests

- (void)testDiskCleanupDefault {
    DFCacheSettings settings = _cache.settings;
    settings.diskCacheCapacity = 1000000; // Target size is going to be 500000
    _cache.settings = settings;
    
    // 1: Store objects.
    // =================
    unsigned long long length = 400000;
    void *raw0 = malloc(length);
    NSData *data0 = [NSData dataWithBytes:raw0 length:length];
    [_cache storeObject:data0 forKey:@"obj_untouched_1" data:data0 transform:nil];
    
    void *raw1 = malloc(length);
    NSData *data1 = [NSData dataWithBytes:raw1 length:length];
    [_cache storeObject:data1 forKey:@"obj_most_recent_access" data:data1 transform:nil];
    
    void *raw2 = malloc(length);
    NSData *data2 = [NSData dataWithBytes:raw2 length:length];
    [_cache storeObject:data2 forKey:@"obj_untouched_2" data:data2 transform:nil];

    void *raw3 = malloc(length);
    NSData *data3 = [NSData dataWithBytes:raw3 length:length];
    NSDictionary *metadata = @{ DFCacheMetaExpirationDateKey : [NSDate dateWithTimeIntervalSinceNow:-10.f] };
    [_cache storeObject:data3 metadata:metadata forKey:@"obj_expired" cost:0.f data:data3 transform:nil];
    
    // 2: Update object latest access data.
    // ====================================
    id (^transform)(NSData *) = ^(NSData *data){
        return data;
    };
    
    sleep(2.f); // Access date step is 1 sec
    
    __block BOOL isWaiting = YES;
    [_cache objectForKey:@"obj_most_recent_access" queue:NULL transform:transform completion:^(id object) {
        isWaiting = NO;
    }];
    DWARF_TEST_WAIT_WHILE(isWaiting, 10.f);
 
    // 3. Cleanup disk cache.
    // ======================
    [_cache cleanupDiskCache];
    
    // 4. Check results.
    // =================
    __block NSUInteger semaphore = 4;
    
    [_cache objectForKey:@"obj_untouched_1" queue:NULL transform:transform completion:^(id object) {
        STAssertNil(object, nil);
        semaphore -= 1;
    }];
    
    [_cache objectForKey:@"obj_untouched_2" queue:NULL transform:transform completion:^(id object) {
        STAssertNil(object, nil);
        semaphore -= 1;
    }];
    
    [_cache objectForKey:@"obj_most_recent_access" queue:NULL transform:transform completion:^(id object) {
        STAssertNotNil(object, nil);
        semaphore -= 1;
    }];
    
    [_cache objectForKey:@"obj_expired" queue:NULL transform:transform completion:^(id object) {
        STAssertNil(object, nil);
        semaphore -= 1;
    }];
    
    DWARF_TEST_WAIT_SEMAPHORE(semaphore, 20.f);
}


- (void)testDiskCleanupNoExpiration {
    DFCacheSettings settings = _cache.settings;
    settings.filesExpirationPeriod = 0.f;
    _cache.settings = settings;
    
    NSDictionary *objects;
    NSArray *keys;
    [self _storeStringsInCache:_cache objects:&objects keys:&keys];
    
    [_cache cleanupDiskCache];
    
    NSUInteger semaphore = [keys count];
    [self _assertContainsObjectsForKeys:keys objects:objects semaphore:&semaphore];
    DWARF_TEST_WAIT_SEMAPHORE(semaphore, 20.f);
}


- (void)testDiskCleanupCustomAlgorithm {
    NSDictionary *objects;
    NSArray *keys;
    [self _storeStringsInCache:_cache objects:&objects keys:&keys];
    
    NSArray *removeKeys = @[ keys[0], keys[3] ];
    NSMutableArray *remainingKeys = [NSMutableArray arrayWithArray:keys];
    [remainingKeys removeObjectsInArray:removeKeys];

    __block NSArray *metatableValues;
    [_cache setDiskCleanupBlock:^NSArray *(NSDictionary *metatable) {
        metatableValues = [metatable objectsForKeys:keys notFoundMarker:[NSNull null]];
        return removeKeys;
    }];
    
    STAssertFalse([metatableValues containsObject:[NSNull null]], nil);
    
    [_cache cleanupDiskCache];
    
    NSUInteger semaphore = [keys count];
    [self _assertContainsObjectsForKeys:remainingKeys objects:objects semaphore:&semaphore];
    [self _assertDoesntContainObjectsForKeys:removeKeys objects:objects semaphore:&semaphore options:DTEntrySourceDisk];
    DWARF_TEST_WAIT_SEMAPHORE(semaphore, 15.f);
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
        [_cache storeCodingObject:(*objects)[key] metadata:nil cost:0.f forKey:key];
    }
}


typedef NS_OPTIONS(NSUInteger, DTEntrySource) {
    DTEntrySourceMemory = (1 << 0),
    DTEntrySourceDisk = (1 << 1)
};


/*! Caller must ensure that semaphore variable is still visible when completion handler is called.
 
 Be aware that you can't just dereference variable with __block storage type.
 
 From "Block Programming Topics":
 
 "__block variables live in storage that is shared between the lexical scope of the variable and all blocks and block copies declared or created within the variable’s lexical scope."
 */
- (void)_assertContainsObjectsForKeys:(NSArray *)keys objects:(NSDictionary *)objects semaphore:(NSUInteger *)semaphore options:(DTEntrySource)options {
    for (NSString *key in keys) {
        if (DF_OPTIONS_IS_ENABLED(options, DTEntrySourceMemory)) {
            NSString *object = [_cache objectForKey:key];
            STAssertNotNil(object, @"mem failure");
            STAssertEqualObjects(objects[key], object, @"mem failure");
        }
        
        if (DF_OPTIONS_IS_ENABLED(options, DTEntrySourceDisk)) {
            [_cache codingObjectForKey:key queue:NULL completion:^(id  object) {
                STAssertNotNil(object, @"disk failure");
                STAssertEqualObjects(objects[key], object, @"disk failure");
                (*semaphore)--;
            }];
        }
    }
}


- (void)_assertContainsObjectsForKeys:(NSArray *)keys objects:(NSDictionary *)objects semaphore:(NSUInteger *)semaphore {
    [self _assertContainsObjectsForKeys:keys objects:objects semaphore:semaphore options:(DTEntrySourceMemory | DTEntrySourceDisk)];
}


- (void)_assertDoesntContainObjectsForKeys:(NSArray *)keys objects:(NSDictionary *)objects semaphore:(NSUInteger *)semaphore options:(DTEntrySource)options {
    for (NSString *key in keys) {
        if (DF_OPTIONS_IS_ENABLED(options, DTEntrySourceMemory)) {
            NSString *object = [_cache objectForKey:key];
            STAssertNil(object, @"mem failure");
        }
        
        if (DF_OPTIONS_IS_ENABLED(options, DTEntrySourceDisk)) {
            [_cache codingObjectForKey:key queue:NULL completion:^(id  object) {
                STAssertNil(object, @"disk failure");
                (*semaphore)--;
            }];
        }
    }
}


- (void)_assertDoesntContainObjectsForKeys:(NSArray *)keys objects:(NSDictionary *)objects semaphore:(NSUInteger *)semaphore {
    [self _assertDoesntContainObjectsForKeys:keys objects:objects semaphore:semaphore options:(DTEntrySourceMemory | DTEntrySourceDisk)];
}

@end
