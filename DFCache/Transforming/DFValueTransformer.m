//
//  DFValueTransformer.m
//  DFCache
//
//  Created by Alexander Grebenyuk on 12/17/14.
//  Copyright (c) 2014 com.github.kean. All rights reserved.
//

#import "DFValueTransformer.h"


@implementation DFValueTransformer

- (id)initWithCoder:(NSCoder *__unused)decoder {
    if (self = [super init]) {
        // do nothing
    }
    return self;
}

- (void)encodeWithCoder:(NSCoder *__unused)coder {
    // do nothing
}

- (NSData *)transformedValue:(id __unused)value {
    [NSException raise:NSInternalInconsistencyException format:@"Abstract method called %@", NSStringFromSelector(_cmd)];
    return nil;
}

- (id)reverseTransfomedValue:(NSData *__unused)data {
    [NSException raise:NSInternalInconsistencyException format:@"Abstract method called %@", NSStringFromSelector(_cmd)];
    return nil;
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


@implementation DFValueTransformerJSON

- (NSData *)transformedValue:(id)value {
    return value ? [NSJSONSerialization dataWithJSONObject:value options:kNilOptions error:nil] : nil;
}

- (id)reverseTransfomedValue:(NSData *)data {
    return data ? [NSJSONSerialization JSONObjectWithData:data options:kNilOptions error:nil] : nil;
}

@end
