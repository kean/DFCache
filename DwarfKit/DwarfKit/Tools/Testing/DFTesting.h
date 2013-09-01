//
//  DFTesting.h
//  Dwarf
//
//  Created by Alexander Grebenyuk on 17.08.13.
//  Copyright (c) 2013 Alexander Grebenyuk. All rights reserved.
//

#import <Foundation/Foundation.h>


#define _DWARF_TEST_RUNTIME 0.1f


#define _DWARF_TEST_RUNLOOP_RUN(timeout) \
    if (timeout < 0.f) { \
        STFail(@"Timeout"); \
        break;\
    } \
    NSDate *date = [NSDate dateWithTimeIntervalSinceNow:_DWARF_TEST_RUNTIME]; \
    timeout -= _DWARF_TEST_RUNTIME; \
    [[NSRunLoop currentRunLoop] runUntilDate:date]; \


#define DWARF_TEST_WAIT_SEMAPHORE(semaphore, timeout) \
({ \
    CGFloat _dwarf_timeout = (timeout); \
    while ((semaphore) > 0) { \
        _DWARF_TEST_RUNLOOP_RUN(_dwarf_timeout) \
    } \
})


#define DWARF_TEST_WAIT_WHILE(predicate, timeout) \
({ \
    CGFloat _dwarf_timeout = (timeout); \
    while (predicate) { \
        _DWARF_TEST_RUNLOOP_RUN(_dwarf_timeout) \
    } \
})
