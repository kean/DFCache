// The MIT License (MIT)
//
// Copyright (c) 2015 Alexander Grebenyuk (github.com/kean).

#import <Foundation/Foundation.h>
#if TARGET_OS_IOS || TARGET_OS_TV
#import <UIKit/UIKit.h>
#endif

#if TARGET_OS_IOS || TARGET_OS_TV
@interface DFCacheImageDecoder : NSObject

+ (nullable UIImage *)decompressedImageWithData:(nonnull NSData *)data;

@end
#endif
