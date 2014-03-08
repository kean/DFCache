/*
 The MIT License (MIT)
 
 Copyright (c) 2013 Alexander Grebenyuk (github.com/kean).
 
 Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:
 
 The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.
 
 THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
 */

#import "DFStorage.h"
#import "NSURL+DFExtendedFileAttributes.h"
#import <XCTest/XCTest.h>

@interface TDFExtendedFileAttributes : XCTestCase

@end

@implementation TDFExtendedFileAttributes {
    NSString *_tempDirectoryPath;
}

- (void)setUp {
    NSString *path = NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES)[0];
    _tempDirectoryPath = [path stringByAppendingPathComponent:@"_extended_attributes_tests"];
    [[NSFileManager defaultManager] createDirectoryAtPath:_tempDirectoryPath withIntermediateDirectories:YES attributes:nil error:nil];
}

- (void)tearDown {
    [[NSFileManager defaultManager] removeItemAtPath:_tempDirectoryPath error:nil];
}

- (void)testExtendedAttributeWriteRead {
    NSString *value = @"_attr_value";
    NSString *key = @"_attr_key";
    
    NSString *filepath = [_tempDirectoryPath stringByAppendingPathComponent:@"_test_01"];
    [[self _tempData] writeToFile:filepath atomically:YES];
    
    NSURL *fileURL = [NSURL fileURLWithPath:filepath];

    int error = [fileURL setExtendedAttributeValue:value forKey:key];
    XCTAssertTrue(!error);
    NSString *valueOut = [fileURL extendedAttributeValueForKey:key error:NULL];
    XCTAssertTrue([valueOut isEqualToString:value]);
}

- (void)testExtendedAttributeRemove {
    NSString *value = @"_attr_value";
    NSString *key = @"_attr_key";
    
    NSString *filepath = [_tempDirectoryPath stringByAppendingPathComponent:@"_test_02"];
    [[self _tempData] writeToFile:filepath atomically:YES];
    
    NSURL *fileURL = [NSURL fileURLWithPath:filepath];
    
    int error = [fileURL setExtendedAttributeValue:value forKey:key];
    XCTAssertTrue(!error);
    error = [fileURL removeExtendedAttributeForKey:key];
    XCTAssertTrue(!error);
    NSString *valueOut = [fileURL extendedAttributeValueForKey:key error:NULL];
    XCTAssertTrue(!valueOut);
}

- (void)testExtendedAttributesList {
    NSString *value = @"_attr_value";
    NSString *key = @"_attr_key";
    NSString *value2 = @"_attr_value_2";
    NSString *key2 = @"_attr_key2";
    
    NSString *filepath = [_tempDirectoryPath stringByAppendingPathComponent:@"_test_03"];
    [[self _tempData] writeToFile:filepath atomically:YES];
    
    NSURL *fileURL = [NSURL fileURLWithPath:filepath];
    
    [fileURL setExtendedAttributeValue:value forKey:key];
    [fileURL setExtendedAttributeValue:value2 forKey:key2];
    
    NSArray *keys = [fileURL extendedAttributesList:NULL];
    XCTAssertTrue([keys containsObject:key]);
    XCTAssertTrue([keys containsObject:key2]);
}

#pragma mark - Helpers

- (NSData *)_tempData {
    size_t dataSize = 10000;
    int *buffer = malloc(dataSize);
    return [NSData dataWithBytesNoCopy:buffer length:dataSize];
}

@end
