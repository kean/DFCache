/*
 The MIT License (MIT)
 
 Copyright (c) 2013 Alexander Grebenyuk (github.com/kean).
 
 Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:
 
 The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.
 
 THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
 */

#import "DFDispatchIO.h"
#import "dwarf_private.h"


@implementation DFDispatchIO

+ (void)readData:(NSString *)path queue:(dispatch_queue_t)queue completion:(void (^)(NSData *))completion {
    if (!completion) {
        return;
    }
    if (!queue) {
        queue = dispatch_get_main_queue();
    }
    if (!path) {
        dispatch_async(queue, ^{
            completion(nil);
        });
        return;
    }
    dispatch_fd_t fd = open([path UTF8String], O_RDONLY);
    dispatch_read(fd, SIZE_MAX, queue, ^(dispatch_data_t data, int error) {
        const void *buffer = NULL;
        size_t length = 0;
        
        DWARF_UNUSED id data_map = dispatch_data_create_map(data, &buffer, &length);
        completion([NSData dataWithBytesNoCopy:(void *)buffer length:length freeWhenDone:YES]);
    });
}

+ (void)writeData:(NSData *)data toFile:(NSString *)path queue:(dispatch_queue_t)queue completion:(void (^)(NSError *))completion {
    if (!data || !path) {
        return;
    }
    if (!queue) {
        queue = dispatch_get_main_queue();
    }
    dispatch_data_t data_dispatch = dispatch_data_create([data bytes], [data length], dispatch_get_main_queue(), ^{
        // Do nothing
    });
    dispatch_fd_t fd = open([path UTF8String], O_WRONLY | O_CREAT | O_TRUNC);
    dispatch_write(fd, data_dispatch, queue, ^(dispatch_data_t data, int code) {
        NSError *error;
        if (code) {
            error = [NSError errorWithDomain:NSPOSIXErrorDomain code:code userInfo:nil];
        }
        completion(error);
    });
}

@end
