// The MIT License (MIT)
//
// Copyright (c) 2015 Alexander Grebenyuk (github.com/kean).

#import <Foundation/Foundation.h>
#import "DFFileStorage.h"

NS_ASSUME_NONNULL_BEGIN

static const unsigned long long DFDiskCacheCapacityUnlimited = 0;

/*! Disk cache extends file storage functionality by providing LRU (least recently used) cleanup. Cleanup doesn't get called automatically.
 */
@interface DFDiskCache : DFFileStorage

- (instancetype)initWithName:(NSString *)name;

/*! Maximum disk cache capacity. Default value is 100 Mb.
 @discussion Not a strict limit. Disk storage is actually cleaned up only when cleanup method gets called.
 */
@property (nonatomic) unsigned long long capacity;

/*! Remaining disk usage after cleanup. The rate must be in the range of 0.0 to 1.0 where 1.0 represents full disk capacity. Default and recommended value is 0.5.
 */
@property (nonatomic) float cleanupRate;

/*! Cleans up disk cache by discarding the least recently used items.
 @discussion Cleanup algorithm runs only if max disk cache capacity is set to non-zero value. Target size is calculated by multiplying disk capacity and cleanup rate.
 */
- (void)cleanup;

/*! Returns path to caches directory.
 */
+ (NSString *)cachesDirectoryPath;

@end

NS_ASSUME_NONNULL_END
