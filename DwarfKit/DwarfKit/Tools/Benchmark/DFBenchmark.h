/*
 The MIT License (MIT)
 
 Copyright (c) 2013 Alexander Grebenyuk (github.com/kean).
 
 Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:
 
 The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.
 
 THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
 */

#import <Foundation/Foundation.h>

/*! Returns the average number of nanoseconds a given block takes to execute.
 @param verbose Enables console output if YES.
 @param block The block to execute.
 */
extern
uint64_t
dwarf_benchmark(BOOL verbose, void (^block)(void));

/*! Returns the average number of nanoseconds a given block takes to execute.
 @param count The number of times to execute the given block.
 @param verbose Enables console output if YES.
 @param block The block to execute.
 @discussion Uses mach_time.h functions to get the most accurate result (time is measured in terms of processor cycles). Substracts the time that for-loop execution takes.
 */
extern
uint64_t
dwarf_benchmark_loop(uint32_t count, BOOL verbose, void (^block)(void));
