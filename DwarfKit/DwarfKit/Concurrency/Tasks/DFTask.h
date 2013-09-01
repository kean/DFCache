//
//  DFOperation.h
//  Dwarf
//
//  Created by Alexander Grebenyuk on 06.08.13.
//  Copyright (c) 2013 Alexander Grebenyuk. All rights reserved.
//

#import <Foundation/Foundation.h>


@interface DFTask : NSObject

@property (nonatomic, readonly) BOOL isExecuting;
@property (nonatomic, readonly) BOOL isFinished;
@property (nonatomic, readonly) BOOL isCancelled;

@property (nonatomic) dispatch_queue_priority_t priority;

@property (nonatomic, copy) void (^completionBlock)(DFTask *task);

- (void)execute;
- (void)finish;
- (void)cancel;

@end
