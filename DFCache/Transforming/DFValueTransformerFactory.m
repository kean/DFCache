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
    // TODO: Set default value transformer factory.
}

+ (id<DFValueTransformerFactory>)defaultFactory {
    return _sharedFactory;
}

+ (void)setDefaultFactory:(id<DFValueTransformerFactory>)factory {
    _sharedFactory = factory;
}

@end
