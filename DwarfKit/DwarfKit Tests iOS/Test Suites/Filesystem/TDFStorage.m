/*
 The MIT License (MIT)
 
 Copyright (c) 2013 Alexander Grebenyuk (github.com/kean).
 
 Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:
 
 The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.
 
 THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
 */

#import "TDFStorage.h"
#import "DFStorage.h"
#import "DFDiskCache.h"


@implementation TDFStorage {
    DFStorage *_storage;
}

- (void)setUp {
    NSString *path = [[DFDiskCache cachesDirectoryPath] stringByAppendingPathComponent:@"_tests_"];
    _storage = [[DFStorage alloc] initWithPath:path];
}

- (void)tearDown {
    [_storage removeAllData];
}

- (void)testBasicFunctionality {
    NSData *data = [self _tempData];
    NSString *key = @"_key";
    
    STAssertNil([_storage dataForKey:key], NULL);
    [_storage setData:data forKey:key];
    STAssertNotNil([_storage dataForKey:key], NULL);

}

- (void)testRemove {
    NSData *data = [self _tempData];
    NSString *key = @"_key";
    
    STAssertNil([_storage dataForKey:key], NULL);
    [_storage setData:data forKey:key];
    STAssertNotNil([_storage dataForKey:key], NULL);
    [_storage removeDataForKey:key];
    STAssertNil([_storage dataForKey:key], NULL);
}

- (void)testRemoveAll {
    NSData *data = [self _tempData];
    NSString *key = @"_key";
    [_storage setData:data forKey:key];
    STAssertNotNil([_storage dataForKey:key], NULL);
    
    NSData *data2 = [self _tempData];
    NSString *key2 = @"_key2";
    [_storage setData:data2 forKey:key2];
    STAssertNotNil([_storage dataForKey:key2], NULL);
    
    [_storage removeAllData];
    STAssertNil([_storage dataForKey:key], NULL);
    STAssertNil([_storage dataForKey:key], NULL);
    
    // Test that storage still works after cleanup.
    STAssertNil([_storage dataForKey:key], NULL);
    [_storage setData:data forKey:key];
    STAssertNotNil([_storage dataForKey:key], NULL);
}

- (void)testContains {
    NSData *data = [self _tempData];
    NSString *key = @"_key";
    
    STAssertFalse([_storage containsDataForKey:key], NULL);
    [_storage setData:data forKey:key];
    STAssertTrue([_storage containsDataForKey:key], NULL);
}

- (void)testPaths {
    NSData *data = [self _tempData];
    NSString *key = @"_key";
    
    NSString *filename = [_storage fileNameForKey:key];
    NSString *path_01 = [[_storage path] stringByAppendingPathComponent:filename];
    NSString *path_02 = [_storage filePathForKey:key];
    NSURL *fileURL = [_storage fileURLForKey:key];
    
    STAssertFalse([[NSFileManager defaultManager] fileExistsAtPath:path_01], NULL);
    STAssertFalse([[NSFileManager defaultManager] fileExistsAtPath:path_02], NULL);
    STAssertFalse([[NSFileManager defaultManager] fileExistsAtPath:fileURL.path], NULL);
    [_storage setData:data forKey:key];
    STAssertTrue([[NSFileManager defaultManager] fileExistsAtPath:path_01], NULL);
    STAssertTrue([[NSFileManager defaultManager] fileExistsAtPath:path_02], NULL);
    STAssertTrue([[NSFileManager defaultManager] fileExistsAtPath:fileURL.path], NULL);
}

- (void)testContents {
    NSData *data = [self _tempData];
    NSString *key = @"_key";
    [_storage setData:data forKey:key];
    STAssertNotNil([_storage dataForKey:key], NULL);
    
    NSData *data2 = [self _tempData];
    NSString *key2 = @"_key2";
    [_storage setData:data2 forKey:key2];
    STAssertNotNil([_storage dataForKey:key2], NULL);
    
    NSArray *contents = [_storage contentsWithResourceKeys:nil];
    STAssertTrue(contents.count == 2, NULL);
    for (NSURL *fileURL in contents) {
        STAssertTrue([fileURL.path rangeOfString:[_storage fileNameForKey:key]].location != NSNotFound ||
                     [fileURL.path rangeOfString:[_storage fileNameForKey:key2]].location != NSNotFound, NULL);
    }
}

#pragma mark - Helpers

- (NSData *)_tempData {
    size_t dataSize = 10000;
    int *buffer = malloc(dataSize);
    return [NSData dataWithBytesNoCopy:buffer length:dataSize];
}

@end
