// The MIT License (MIT)
//
// Copyright (c) 2015 Alexander Grebenyuk (github.com/kean).

#import "DFCache.h"
#import <XCTest/XCTest.h>

@interface DFCache (Tests)

- (void)storeStringsWithCount:(NSUInteger)count strings:(NSDictionary *__autoreleasing *)strings;

@end


@interface TDFCacheUnsupportedDummy : NSObject

- (NSData *)dataRepresentation;
- (instancetype)initWithData:(NSData *)data;

@end


@interface TDFValueTransformerCacheUnsupportedDummy : DFValueTransformer

@end
