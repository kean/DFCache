// The MIT License (MIT)
//
// Copyright (c) 2015 Alexander Grebenyuk (github.com/kean).

#import "DFFileStorage.h"
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

    int error = [fileURL df_setExtendedAttributeValue:value forKey:key];
    XCTAssertTrue(!error);
    NSString *valueOut = [fileURL df_extendedAttributeValueForKey:key error:NULL];
    XCTAssertTrue([valueOut isEqualToString:value]);
}

- (void)testExtendedAttributeRemove {
    NSString *value = @"_attr_value";
    NSString *key = @"_attr_key";
    
    NSString *filepath = [_tempDirectoryPath stringByAppendingPathComponent:@"_test_02"];
    [[self _tempData] writeToFile:filepath atomically:YES];
    
    NSURL *fileURL = [NSURL fileURLWithPath:filepath];
    
    int error = [fileURL df_setExtendedAttributeValue:value forKey:key];
    XCTAssertTrue(!error);
    error = [fileURL df_removeExtendedAttributeForKey:key];
    XCTAssertTrue(!error);
    NSString *valueOut = [fileURL df_extendedAttributeValueForKey:key error:NULL];
    XCTAssertTrue(!valueOut);
}

- (void)testdf_extendedAttributesList {
    NSString *value = @"_attr_value";
    NSString *key = @"_attr_key";
    NSString *value2 = @"_attr_value_2";
    NSString *key2 = @"_attr_key2";
    
    NSString *filepath = [_tempDirectoryPath stringByAppendingPathComponent:@"_test_03"];
    [[self _tempData] writeToFile:filepath atomically:YES];
    
    NSURL *fileURL = [NSURL fileURLWithPath:filepath];
    
    [fileURL df_setExtendedAttributeValue:value forKey:key];
    [fileURL df_setExtendedAttributeValue:value2 forKey:key2];
    
    NSArray *keys = [fileURL df_extendedAttributesList:NULL];
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
