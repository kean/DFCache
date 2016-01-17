// The MIT License (MIT)
//
// Copyright (c) 2015 Alexander Grebenyuk (github.com/kean).

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

extern NSString *const DFValueTransformerNSCodingName;
extern NSString *const DFValueTransformerJSONName;

#if TARGET_OS_IOS || TARGET_OS_TV
extern NSString *const DFValueTransformerUIImageName;
#endif


@protocol DFValueTransforming <NSObject>

- (nullable NSData *)transformedValue:(id)value;
- (nullable id)reverseTransfomedValue:(NSData *)data;

@optional
/*! The cost that is associated with the value in the memory cache. Typically, the obvious cost is the size of the object in bytes.
 */
- (NSUInteger)costForValue:(id)value;

@end


@interface DFValueTransformer : NSObject <DFValueTransforming>

@end


@interface DFValueTransformerNSCoding : DFValueTransformer

@end


@interface DFValueTransformerJSON : DFValueTransformer

@end


#if TARGET_OS_IOS || TARGET_OS_TV

@interface DFValueTransformerUIImage : DFValueTransformer

/*! The quality of the resulting JPEG image, expressed as a value from 0.0 to 1.0. The value 0.0 represents the maximum compression (or lowest quality) while the value 1.0 represents the least compression (or best quality).
 @discussion Applies only or images that don't have an alpha channel and cab be encoded in JPEG format.
 */
@property (nonatomic) float compressionQuality;

@property (nonatomic) BOOL allowsImageDecompression;

@end

#endif

NS_ASSUME_NONNULL_END
