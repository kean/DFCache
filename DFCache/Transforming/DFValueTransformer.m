//
//  DFValueTransformer.m
//  DFCache
//
//  Created by Alexander Grebenyuk on 12/17/14.
//  Copyright (c) 2014 com.github.kean. All rights reserved.
//

#import "DFValueTransformer.h"


@implementation DFValueTransformer

- (id)initWithCoder:(NSCoder *)decoder {
    if (self = [super init]) {
        // do nothing
    }
    return self;
}

- (void)encodeWithCoder:(NSCoder *)coder {
    // do nothing
}

@end


@implementation DFValueTransformerNSCoding

- (NSData *)transformedValue:(id)value {
    return value ? [NSKeyedArchiver archivedDataWithRootObject:value] : nil;
}

- (id)reverseTransfomedValue:(NSData *)data {
    return data ? [NSKeyedUnarchiver unarchiveObjectWithData:data] : nil;
}

@end
