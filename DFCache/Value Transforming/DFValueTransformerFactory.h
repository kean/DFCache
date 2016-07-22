// The MIT License (MIT)
//
// Copyright (c) 2015 Alexander Grebenyuk (github.com/kean).

#import <Foundation/Foundation.h>
#import "DFValueTransformer.h"

NS_ASSUME_NONNULL_BEGIN

@protocol DFValueTransformerFactory <NSObject>

- (nullable NSString *)valueTransformerNameForValue:(id)value;

/*! Returns value transformer registered for a given name.
 */
- (nullable id<DFValueTransforming>)valueTransformerForName:(nullable NSString *)name;

@end


@interface DFValueTransformerFactory : NSObject <DFValueTransformerFactory>

/*! Dependency injector.
 */
+ (id<DFValueTransformerFactory>)defaultFactory;

/*! Dependency injector.
 */
+ (void)setDefaultFactory:(id<DFValueTransformerFactory>)factory;

/*! Registers the provided value transformer with a given identifier.
 */
- (void)registerValueTransformer:(id<DFValueTransforming>)valueTransformer forName:(NSString *)name;

@end

NS_ASSUME_NONNULL_END
