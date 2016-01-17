// The MIT License (MIT)
//
// Copyright (c) 2015 Alexander Grebenyuk (github.com/kean).

#import "DFDiskCache.h"
#import <XCTest/XCTest.h>

@interface TDFDiskCache : XCTestCase

@end

@implementation TDFDiskCache {
    DFDiskCache *_diskCache;
}

- (void)setUp {
    NSString *path = [[DFDiskCache cachesDirectoryPath] stringByAppendingPathComponent:@"_tests_"];
    _diskCache = [[DFDiskCache alloc] initWithPath:path error:nil];
}

- (void)tearDown {
    [_diskCache removeAllData];
}

- (void)testDiskCleanup {
    unsigned long long length = 400000;
    _diskCache.capacity = length + 10000;
    _diskCache.cleanupRate = 1.f; // Only one should remain.
    
    NSArray *keys = @[ @"_key_1", @"_key_2", @"_key_3", @"_key_4", @"_key_5" ];
    
    for (NSString *key in keys) {
        NSData *data = [self _dataWithLength:length];
        [_diskCache setData:data forKey:key];
    }
    
    [[NSRunLoop currentRunLoop] runUntilDate:[NSDate dateWithTimeIntervalSinceNow:1.1f]];
    
    [_diskCache dataForKey:keys[1]];
    
    [_diskCache cleanup];
    
    NSUInteger remainingDataCount = 0;
    for (NSString *key in keys) {
        if ([_diskCache containsDataForKey:key]) {
            remainingDataCount++;
        }
    }
    XCTAssertTrue(remainingDataCount == 1);
    XCTAssertTrue([_diskCache containsDataForKey:keys[1]]);
}

#pragma mark - Helpers 

- (NSData *)_dataWithLength:(unsigned long long)length {
    void *raw = malloc(length);
    return [NSData dataWithBytes:raw length:length];
}

@end
