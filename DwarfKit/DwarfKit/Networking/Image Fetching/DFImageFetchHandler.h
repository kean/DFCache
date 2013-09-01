//
//  DDImageFetchHandler.h
//  Dwarf
//
//  Created by Alexander Grebenyuk on 7/20/13.
//  Copyright (c) 2013 Alexander Grebenyuk. All rights reserved.
//

#import "DFNetworkingConstants.h"


@interface DFImageFetchHandler : NSObject

@property (nonatomic, copy) void (^success)(UIImage *, DFResponseSource);
@property (nonatomic, copy) void (^failure)(NSError *);

- (void)setSuccess:(void (^)(UIImage *image, DFResponseSource source))success;
- (void)setFailure:(void (^)(NSError * error))failure;

+ (instancetype)handlerWithSuccess:(void (^)(UIImage *image, DFResponseSource source))success failure:(void (^)(NSError *failure))failure;

@end
