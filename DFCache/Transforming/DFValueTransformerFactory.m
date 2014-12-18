//
//  DFValueTransformerFactory.m
//  DFCache
//
//  Created by Alexander Grebenyuk on 12/17/14.
//  Copyright (c) 2014 com.github.kean. All rights reserved.
//

#import "DFValueTransformerFactory.h"

@implementation DFValueTransformerFactory

static id<DFValueTransformerFactory> _sharedFactory;

+ (void)initialize {
    [self setDefaultFactory:[DFValueTransformerFactory new]];
}

#pragma mark - <DFValueTransformerFactory>

- (id<DFValueTransforming>)valueTransformerForValue:(id)value {
    if ([value conformsToProtocol:@protocol(NSCoding)]) {
        return [DFValueTransformerNSCoding new];
    } else {
        return nil;
    }
}

#pragma mark - Dependency Injectors

+ (id<DFValueTransformerFactory>)defaultFactory {
    return _sharedFactory;
}

+ (void)setDefaultFactory:(id<DFValueTransformerFactory>)factory {
    _sharedFactory = factory;
}

@end
