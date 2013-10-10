//
//  DFProcessingHandler.m
//  DwarfKit
//
//  Created by kean on 10.10.13.
//  Copyright (c) 2013 com.github.kean. All rights reserved.
//

#import "DFProcessingHandler.h"

@implementation DFProcessingHandler

+ (instancetype)handlerWithCompletion:(DFProcessingCompletion)completion {
   DFProcessingHandler *handler = [DFProcessingHandler new];
   handler.completion = completion;
   return handler;
}

@end
