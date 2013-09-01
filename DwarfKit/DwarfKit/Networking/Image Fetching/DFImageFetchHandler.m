//
//  DDImageFetchHandler.m
//  Dwarf
//
//  Created by Alexander Grebenyuk on 7/20/13.
//  Copyright (c) 2013 Alexander Grebenyuk. All rights reserved.
//

#import "DFImageFetchHandler.h"

@implementation DFImageFetchHandler

+ (instancetype)handlerWithSuccess:(void (^)(UIImage *, DFResponseSource))success failure:(void (^)(NSError *))failure {
   DFImageFetchHandler *handler = [DFImageFetchHandler new];
   handler.success = success;
   handler.failure = failure;
   return handler;
}

@end
