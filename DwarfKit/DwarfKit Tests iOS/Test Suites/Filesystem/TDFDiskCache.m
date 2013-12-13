/*
 The MIT License (MIT)
 
 Copyright (c) 2013 Alexander Grebenyuk (github.com/kean).
 
 Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:
 
 The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.
 
 THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
 */

#import "TDFDiskCache.h"
#import "DFDiskCache.h"
#import "DFTesting.h"


@implementation TDFDiskCache {
    DFDiskCache *_diskCache;
}

- (void)setUp {
    NSString *path = [[DFDiskCache cachesDirectoryPath] stringByAppendingPathComponent:@"_tests_"];
    _diskCache = [[DFDiskCache alloc] initWithPath:path];
}

- (void)tearDown {
    [_diskCache removeAllData];
}

- (void)testDiskCleanup {
    unsigned long long length = 400000;
    _diskCache.capacity = length + 10000;
    _diskCache.cleanupRate = 1.f; // Only one should remain.
    
    NSArray *keys = @[ @"_key_1", @"_key_2", @"_key_3" ];
    
    NSData *data0 = [self _dataWithLength:length];
    [_diskCache setData:data0 forKey:keys[0]];
    
    NSData *data1 = [self _dataWithLength:length];
    [_diskCache setData:data1 forKey:keys[1]];
    
    NSData *data2 = [self _dataWithLength:length];
    [_diskCache setData:data2 forKey:keys[2]];

    [_diskCache cleanup];
    
    NSUInteger remainingDataCount = 0;
    for (NSString *key in keys) {
        if ([_diskCache containsDataForKey:key]) {
            remainingDataCount++;
        }
    }
    STAssertTrue(remainingDataCount == 1, NULL);
}

#pragma mark - Helpers 

- (NSData *)_dataWithLength:(unsigned long long)length {
    void *raw = malloc(length);
    return [NSData dataWithBytes:raw length:length];
}

@end
