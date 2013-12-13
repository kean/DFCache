/*
 The MIT License (MIT)
 
 Copyright (c) 2013 Alexander Grebenyuk (github.com/kean).
 
 Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:
 
 The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.
 
 THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
 */

#import "DFDiskCache.h"
#import "dwarf_private.h"


@implementation DFDiskCache

- (id)initWithPath:(NSString *)path {
    if (self = [super initWithPath:path]) {
        [super setDelegate:self];
    }
    return self;
}

- (void)setDelegate:(id<DFStorageDelegate>)delegate {
    [NSException raise:NSInternalInconsistencyException format:@"Attempting to change DFDiskCache delegate"];
}

- (void)storage:(DFStorage *)storage didReadFileAtURL:(NSURL *)fileURL {
    if (_capacity == DFDiskCacheCapacityUnlimited) {
        return;
    }
    [fileURL setResourceValue:[NSDate date] forKey:NSURLAttributeModificationDateKey error:nil];
}

- (void)cleanup {
    if (_capacity == DFDiskCacheCapacityUnlimited) {
        return;
    }
    NSArray *resourceKeys = @[NSURLContentModificationDateKey, NSURLFileAllocatedSizeKey];
    NSArray *contents = [self contentsWithResourceKeys:resourceKeys];
    NSMutableDictionary *fileAttributes = [NSMutableDictionary dictionary];
    _dwarf_bytes contentsSize = 0;
    for (NSURL *fileURL in contents) {
        NSDictionary *resourceValues = [fileURL resourceValuesForKeys:resourceKeys error:NULL];
        if (resourceValues) {
            fileAttributes[fileURL] = resourceValues;
            NSNumber *fileSize = resourceValues[NSURLFileAllocatedSizeKey];
            contentsSize += [fileSize unsignedLongLongValue];
        }
    }
    if (contentsSize < _capacity) {
        return;
    }
    const _dwarf_bytes desiredSize = _capacity * _cleanupRate;
    NSArray *sortedFiles = [fileAttributes keysSortedByValueWithOptions:NSSortConcurrent usingComparator:^NSComparisonResult(id obj1, id obj2) {
        return [obj1[NSURLContentModificationDateKey] compare:obj2[NSURLContentModificationDateKey]];
    }];
    for (NSURL *fileURL in sortedFiles) {
        if (contentsSize < desiredSize) {
            break;
        }
        if ([[NSFileManager defaultManager] removeItemAtURL:fileURL error:nil]) {
            NSNumber *fileSize = fileAttributes[fileURL][NSURLFileAllocatedSizeKey];
            contentsSize -= [fileSize unsignedLongLongValue];
        }
    }
}

+ (NSString *)cachesDirectoryPath {
    return NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES)[0];
}

@end
