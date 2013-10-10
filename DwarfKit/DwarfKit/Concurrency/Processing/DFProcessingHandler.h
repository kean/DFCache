//
//  DFProcessingHandler.h
//  DwarfKit
//
//  Created by kean on 10.10.13.
//  Copyright (c) 2013 com.github.kean. All rights reserved.
//

#import <Foundation/Foundation.h>


typedef void (^DFProcessingCompletion)(id output, BOOL fromCache);


@interface DFProcessingHandler : NSObject

@property (nonatomic, copy) DFProcessingCompletion completion;

+ (instancetype)handlerWithCompletion:(DFProcessingCompletion)completion;

@end
