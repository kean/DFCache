//
//  DFTask+DFTaskPrivate.h
//  Dwarf
//
//  Created by Alexander Grebenyuk on 07.08.13.
//  Copyright (c) 2013 Alexander Grebenyuk. All rights reserved.
//

#import "DFTask.h"


@protocol _DFTaskDelegate;


@interface DFTask (DFTaskPrivate)

- (void)_setImplDelegate:(id<_DFTaskDelegate>)delegate;
- (void)_setExecuting:(BOOL)executing;
- (void)_setFinished:(BOOL)finished;
- (void)_setCanceled:(BOOL)canceled;

@end


@protocol _DFTaskDelegate <NSObject>

- (void)_taskDidFinish:(DFTask *)task;

@end