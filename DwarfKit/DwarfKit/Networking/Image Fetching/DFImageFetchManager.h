//
//  DFImageFetchManager.h
//  Dwarf
//
//  Created by Alexander Grebenyuk on 8/11/13.
//  Copyright (c) 2013 Alexander Grebenyuk. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "DFImageCaching.h"
#import "DFImageFetchHandler.h"
#import "DFImageFetchTask.h"
#import "DFTaskQueue.h"

/*!
 Image fetching with extreme performance.
 
 Key features:
 - Performance and scalability. Built entirely on top of GCD. DFImageFetchManager is able to maintain thousands of image requests/request cancellations per second. Even on older devices.
 - JPEG images are decompressed via libjpeg-turbo. JPEG decompression is 3-4 times faster then iOS codec.
 - Fully customisable cache (you can provide custom cache implementation or even use NSURLCache, cache implementation can be changed for the particular request, etc).
 - Resources with the same URL are never downloaded twice.
 */
@interface DFImageFetchManager : NSObject

/*! Initializes manager with specified name.
 @param name Name isn't used anywhere in the underlying implementation.
 @discussion Doesn't initialize image cache. You need to provide you own implementation (or use DFCache explicitly).
 */
- (id)initWithName:(NSString *)name;

@property (nonatomic, strong, readonly) NSString *name;
 
/*! Task queue that is used to execute image fetch tasks.
 */
@property (nonatomic, strong, readonly) DFTaskQueue *queue;

/*! Cache used by image fetch manager.
 @discussion If cache is set to nil then DFImageFetchTask uses shared NSURLCache.
 */
@property (nonatomic, strong) id<DFImageCaching> cache;

// TODO: Comments
+ (instancetype)shared;

/*!
 @discussion Returned DFImageFetchTask is guranteed not to be executed until the next run of main run loop.
 */
- (DFImageFetchTask *)fetchImageWithURL:(NSString *)imageURL handler:(DFImageFetchHandler *)handler;
- (void)cancelFetchingWithURL:(NSString *)imageURL handler:(DFImageFetchHandler *)handler;
- (void)prefetchImageWithURL:(NSString *)imageURL;

@end
