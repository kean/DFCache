//
//  DFTaskQueue.h
//  Dwarf
//
//  Created by Alexander Grebenyuk on 06.08.13.
//  Copyright (c) 2013 Alexander Grebenyuk. All rights reserved.
//

#import <Foundation/Foundation.h>


@class DFTask;


/*! Regulates execution of DFTask objects. DFTaskQueue and DFTask pair is a lightweight NSOperationQueue and NSOperation analog.
 
 Features:
 - Performance. Written entirely on top of grand central dispatch. Requires all methods to be called from the main thread to avoid unnecessary synchronizations.
 */
@interface DFTaskQueue : NSObject

@property (nonatomic) NSUInteger maxConcurrentTaskCount;
@property (nonatomic, getter = isPaused) BOOL paused;
@property (nonatomic, strong, readonly) NSOrderedSet *tasks;

- (void)addTask:(DFTask *)task;
- (void)cancelAllTasks;

@end
