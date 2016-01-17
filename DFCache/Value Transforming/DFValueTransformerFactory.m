// The MIT License (MIT)
//
// Copyright (c) 2015 Alexander Grebenyuk (github.com/kean).

#import "DFValueTransformerFactory.h"

#if TARGET_OS_IOS || TARGET_OS_TV
#import <UIKit/UIKit.h>
#endif

@implementation DFValueTransformerFactory {
    NSMutableDictionary *_transformers;
}

static id<DFValueTransformerFactory> _sharedFactory;

+ (void)initialize {
    [self setDefaultFactory:[DFValueTransformerFactory new]];
}

- (instancetype)init {
    if (self = [super init]) {
        _transformers = [NSMutableDictionary new];

        [self registerValueTransformer:[DFValueTransformerNSCoding new] forName:DFValueTransformerNSCodingName];
        [self registerValueTransformer:[DFValueTransformerJSON new] forName:DFValueTransformerJSONName];
        
#if TARGET_OS_IOS || TARGET_OS_TV
        DFValueTransformerUIImage *transformerUIImage = [DFValueTransformerUIImage new];
        transformerUIImage.compressionQuality = 0.75f;
        transformerUIImage.allowsImageDecompression = YES;
        [self registerValueTransformer:transformerUIImage forName:DFValueTransformerUIImageName];
#endif
    }
    return self;
}

- (void)registerValueTransformer:(id<DFValueTransforming>)valueTransformer forName:(NSString *)name {
    _transformers[name] = valueTransformer;
}

- (id<DFValueTransforming>)valueTransformerForName:(NSString *)name {
    return _transformers[name];
}

#pragma mark - <DFValueTransformerFactory>

- (NSString *)valueTransformerNameForValue:(id)value {
#if TARGET_OS_IOS || TARGET_OS_TV
    if ([value isKindOfClass:[UIImage class]]) {
        return DFValueTransformerUIImageName;
    }
#endif
    
    if ([value conformsToProtocol:@protocol(NSCoding)]) {
        return DFValueTransformerNSCodingName;
    }
    
    return nil;
}

#pragma mark - Dependency Injectors

+ (id<DFValueTransformerFactory>)defaultFactory {
    return _sharedFactory;
}

+ (void)setDefaultFactory:(id<DFValueTransformerFactory>)factory {
    _sharedFactory = factory;
}

@end
