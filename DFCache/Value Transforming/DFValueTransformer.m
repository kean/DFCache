// The MIT License (MIT)
//
// Copyright (c) 2015 Alexander Grebenyuk (github.com/kean).

#import "DFValueTransformer.h"
#import "DFCacheImageDecoder.h"


NSString *const DFValueTransformerNSCodingName = @"DFValueTransformerNSCodingName";
NSString *const DFValueTransformerJSONName = @"DFValueTransformerJSONName";

#if TARGET_OS_IOS || TARGET_OS_TV
NSString *const DFValueTransformerUIImageName = @"DFValueTransformerUIImageName";
#endif


@implementation DFValueTransformer

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


#if TARGET_OS_IOS || TARGET_OS_TV

@implementation DFValueTransformerUIImage

- (instancetype)init {
    if (self = [super init]) {
        _compressionQuality = 0.75f;
        _allowsImageDecompression = YES;
    }
    return self;
}

- (NSData *)transformedValue:(id)value {
    BOOL isOpaque = [self _isImageOpaque:value];
    return isOpaque ? UIImageJPEGRepresentation(value, self.compressionQuality) : UIImagePNGRepresentation(value);
}

- (BOOL)_isImageOpaque:(UIImage *)image {
    CGImageAlphaInfo info = CGImageGetAlphaInfo(image.CGImage);
    return !(info == kCGImageAlphaFirst ||
             info == kCGImageAlphaLast ||
             info == kCGImageAlphaPremultipliedFirst ||
             info == kCGImageAlphaPremultipliedLast);
}

- (id)reverseTransfomedValue:(NSData *)data {
    if (self.allowsImageDecompression) {
        return [DFCacheImageDecoder decompressedImageWithData:data];
    } else {
        return [[UIImage alloc] initWithData:data scale:[UIScreen mainScreen].scale];
    }
}

- (NSUInteger)costForValue:(id)value {
    CGImageRef image = ((UIImage *)value).CGImage;
    NSUInteger bitsPerPixel = CGImageGetBitsPerPixel(image);
    return (CGImageGetWidth(image) * CGImageGetHeight(image) * bitsPerPixel) / 8; // Return number of bytes in image bitmap.
}

@end

#endif
