//
//  DFBenchmark.h
//  Dwarf
//
//  Created by Alexander Grebenyuk on 13.08.13.
//  Copyright (c) 2013 Alexander Grebenyuk. All rights reserved.
//

#import <Foundation/Foundation.h>


/*! Executes block once. Can be used directly in your code while debugging.
 */
extern
uint64_t
dwarf_benchmark(BOOL verbose, void (^block)(void));

/*! Returns number of nanoseconds code wrapped in block takes to execute.
 @param count Number of iterations to run.
 @param verbose Prints benchmark results if YES.
 @param block Actual work wrapped inside the block.
 @discussion Uses mach_time.h functions to calculate the most accurate result (time is measured in processor cicles). Substracts the time for-loop loop and time wrapper-block execution takes (benchmark implementation). Most algorithms are borrowed from libdispatch benchmark.c
 */
extern
uint64_t
dwarf_benchmark_loop(uint32_t count, BOOL verbose, void (^block)(void));
