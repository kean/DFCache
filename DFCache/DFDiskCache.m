// The MIT License (MIT)
//
// Copyright (c) 2015 Alexander Grebenyuk (github.com/kean).

#import "DFCachePrivate.h"
#import "DFDiskCache.h"

@implementation DFDiskCache

- (instancetype)initWithPath:(NSString *)path error:(NSError **)error {
    if (self = [super initWithPath:path error:error]) {
        _capacity = 1024 * 1024 * 100; // 100 Mb
        _cleanupRate = 0.5f;
    }
    return self;
}

- (instancetype)initWithName:(NSString *)name {
    NSString *directoryPath = [[DFDiskCache cachesDirectoryPath] stringByAppendingPathComponent:name];
    return [self initWithPath:directoryPath error:nil];
}

- (void)cleanup {
    if (_capacity == DFDiskCacheCapacityUnlimited) {
        return;
    }
    NSArray *resourceKeys = @[NSURLContentAccessDateKey, NSURLFileAllocatedSizeKey];
    NSArray *contents = [self contentsWithResourceKeys:resourceKeys];
    NSMutableDictionary *fileAttributes = [NSMutableDictionary dictionary];
    _dwarf_cache_bytes contentsSize = 0;
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
    const _dwarf_cache_bytes desiredSize = _capacity * _cleanupRate;
    NSArray *sortedFiles = [fileAttributes keysSortedByValueWithOptions:NSSortConcurrent usingComparator:^NSComparisonResult(id obj1, id obj2) {
        return [obj1[NSURLContentAccessDateKey] compare:obj2[NSURLContentAccessDateKey]];
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
    return [NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES) firstObject];
}

#pragma mark - Miscellaneous

- (NSString *)debugDescription {
    return [NSString stringWithFormat:@"<%@ %p> { capacity: %@; usage: %@; files: %lu }", [self class], self, _dwarf_bytes_to_str(self.capacity), _dwarf_bytes_to_str(self.contentsSize), (unsigned long)[self contentsWithResourceKeys:nil].count];
}

@end
