//
//  DFOperation.m
//  Dwarf
//
//  Created by Alexander Grebenyuk on 06.08.13.
//  Copyright (c) 2013 Alexander Grebenyuk. All rights reserved.
//

#import "DFTask.h"
#import "DFTask+DFTaskPrivate.h"


@implementation DFTask {
    __weak id<_DFTaskDelegate> _impl_delegate;
}


- (BOOL)isEqual:(id)object {
    return self == object;
}


- (void)execute {
    return;
}


- (void)finish {
    [_impl_delegate _taskDidFinish:self];
}


- (void)cancel {
    [self _setCanceled:YES];
}

#pragma mark - DFTask+DFTaskPrivate

- (void)_setImplDelegate:(id<_DFTaskDelegate>)delegate {
    _impl_delegate = delegate;
}


- (void)_setCanceled:(BOOL)canceled {
    _isCancelled = canceled;
}


- (void)_setExecuting:(BOOL)executing {
    _isExecuting = executing;
}


- (void)_setFinished:(BOOL)finished {
    _isFinished = finished;
}

@end
