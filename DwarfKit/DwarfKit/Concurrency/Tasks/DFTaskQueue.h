/*
 The MIT License (MIT)
 
 Copyright (c) 2013 Alexander Grebenyuk (github.com/kean).
 
 Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:
 
 The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.
 
 THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
 */

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
