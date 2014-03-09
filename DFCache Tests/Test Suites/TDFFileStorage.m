/*
 The MIT License (MIT)
 
 Copyright (c) 2013 Alexander Grebenyuk (github.com/kean).
 
 Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:
 
 The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.
 
 THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
 */

#import "DFFileStorage.h"
#import "DFDiskCache.h"
#import <XCTest/XCTest.h>

@interface TDFFileStorage : XCTestCase

@end

@implementation TDFFileStorage {
    DFFileStorage *_storage;
}

- (void)setUp {
    NSString *path = [[DFDiskCache cachesDirectoryPath] stringByAppendingPathComponent:@"_tests_"];
    _storage = [[DFFileStorage alloc] initWithPath:path error:nil];
}

- (void)tearDown {
    [_storage removeAllData];
}

- (void)testBasicFunctionality {
    NSData *data = [self _tempData];
    NSString *key = @"_key";
    
    XCTAssertNil([_storage dataForKey:key]);
    [_storage setData:data forKey:key];
    XCTAssertNotNil([_storage dataForKey:key]);

}

- (void)testRemove {
    NSData *data = [self _tempData];
    NSString *key = @"_key";
    
    XCTAssertNil([_storage dataForKey:key]);
    [_storage setData:data forKey:key];
    XCTAssertNotNil([_storage dataForKey:key]);
    [_storage removeDataForKey:key];
    XCTAssertNil([_storage dataForKey:key]);
}

- (void)testRemoveAll {
    NSData *data = [self _tempData];
    NSString *key = @"_key";
    [_storage setData:data forKey:key];
    XCTAssertNotNil([_storage dataForKey:key]);
    
    NSData *data2 = [self _tempData];
    NSString *key2 = @"_key2";
    [_storage setData:data2 forKey:key2];
    XCTAssertNotNil([_storage dataForKey:key2]);
    
    [_storage removeAllData];
    XCTAssertNil([_storage dataForKey:key]);
    XCTAssertNil([_storage dataForKey:key]);
    
    // Test that storage still works after cleanup.
    XCTAssertNil([_storage dataForKey:key]);
    [_storage setData:data forKey:key];
    XCTAssertNotNil([_storage dataForKey:key]);
}

- (void)testContains {
    NSData *data = [self _tempData];
    NSString *key = @"_key";
    
    XCTAssertFalse([_storage containsDataForKey:key]);
    [_storage setData:data forKey:key];
    XCTAssertTrue([_storage containsDataForKey:key]);
}

- (void)testPaths {
    NSData *data = [self _tempData];
    NSString *key = @"_key";
    
    NSString *filename = [_storage filenameForKey:key];
    NSString *path_01 = [[_storage path] stringByAppendingPathComponent:filename];
    NSString *path_02 = [_storage pathForKey:key];
    NSURL *fileURL = [_storage URLForKey:key];
    
    XCTAssertFalse([[NSFileManager defaultManager] fileExistsAtPath:path_01]);
    XCTAssertFalse([[NSFileManager defaultManager] fileExistsAtPath:path_02]);
    XCTAssertFalse([[NSFileManager defaultManager] fileExistsAtPath:fileURL.path]);
    [_storage setData:data forKey:key];
    XCTAssertTrue([[NSFileManager defaultManager] fileExistsAtPath:path_01]);
    XCTAssertTrue([[NSFileManager defaultManager] fileExistsAtPath:path_02]);
    XCTAssertTrue([[NSFileManager defaultManager] fileExistsAtPath:fileURL.path]);
}

- (void)testContents {
    NSData *data = [self _tempData];
    NSString *key = @"_key";
    [_storage setData:data forKey:key];
    XCTAssertNotNil([_storage dataForKey:key]);
    
    NSData *data2 = [self _tempData];
    NSString *key2 = @"_key2";
    [_storage setData:data2 forKey:key2];
    XCTAssertNotNil([_storage dataForKey:key2]);
    
    NSArray *contents = [_storage contentsWithResourceKeys:nil];
    XCTAssertTrue(contents.count == 2);
    for (NSURL *fileURL in contents) {
        XCTAssertTrue([fileURL.path rangeOfString:[_storage filenameForKey:key]].location != NSNotFound ||
                     [fileURL.path rangeOfString:[_storage filenameForKey:key2]].location != NSNotFound);
    }
}

#pragma mark - Helpers

- (NSData *)_tempData {
    size_t dataSize = 10000;
    int *buffer = malloc(dataSize);
    return [NSData dataWithBytesNoCopy:buffer length:dataSize];
}

@end
