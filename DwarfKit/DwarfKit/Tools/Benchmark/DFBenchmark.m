//
//  DFBenchmark.m
//  Dwarf
//
//  Created by Alexander Grebenyuk on 13.08.13.
//  Copyright (c) 2013 Alexander Grebenyuk. All rights reserved.
//

#import "DFBenchmark.h"
#import "dwarf_private.h"
#import <mach/mach_time.h>


typedef struct {
    mach_timebase_info_data_t timebase_info;
    uint64_t loop_cost;
} _dwarf_benchmark_env;

static _dwarf_benchmark_env _benchmark_env;


void
_dwarf_print_benchmark(uint64_t ns, uint32_t count);
uint64_t
_dwarf_benchmark_loop(uint32_t count, void (^block)(void));


static void
_dwarf_benchmark_env_init() {
    // Get mach timebase info
    mach_timebase_info_data_t timebase_info;
    DWARF_UNUSED kern_return_t kern = mach_timebase_info(&timebase_info);
    NSCAssert(kern == 0, @"_dwarf_benchmark_env_init: mach_timebase_info failed");
    
    _dwarf_benchmark_env env = {
        .timebase_info = timebase_info,
    };
    _benchmark_env = env;
    
    // Calculate for-loop and block execution overhead
    void (^dummy)(void) = ^{};
   
    uint32_t count = 1000000;
    uint64_t loop_cost = _dwarf_benchmark_loop(count, dummy);
    _benchmark_env.loop_cost = loop_cost;
}


uint64_t
dwarf_benchmark(BOOL verbose, void (^block)(void)) {
    return dwarf_benchmark_loop(1, verbose, block);
}


uint64_t
dwarf_benchmark_loop(uint32_t count, BOOL verbose, void (^block)(void)) {
    static dispatch_once_t once;
    dispatch_once(&once, ^{
        _dwarf_benchmark_env_init();
    });
    
    uint64_t result = _dwarf_benchmark_loop(count, block);
    result -= _benchmark_env.loop_cost;
    
    if (verbose) {
        _dwarf_print_benchmark(result, count);
    }
    
    return result;
}


uint64_t
_dwarf_benchmark_loop(uint32_t count, void (^block)(void)) {
    uint32_t i = 0;
    uint64_t start;
    uint64_t delta;
    
    start = mach_absolute_time();
    do {
        block();
        i++;
    } while (i < count);
    delta = mach_absolute_time() - start;
    
    uint64_t result = delta;
    result *= _benchmark_env.timebase_info.numer;
    result /= (_benchmark_env.timebase_info.denom * count);
    
    return result;
}


void
_dwarf_print_benchmark(uint64_t ns, uint32_t count) {
    NSLog(@"Benchmark execution: %lld ns, %.2f ms, %.4f sec.", ns, ns / 1e6, ns / 1e9);
    
    if (count > 1) {
        uint64_t full_time = ns * count;
        NSLog(@"Benchmark execution (%i iterations): %lld ns, %.2f ms, %.4f sec.", count, full_time, full_time / 1e6, full_time / 1e9);
    }
}
