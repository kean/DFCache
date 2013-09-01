//
//  DFImageCaching.h
//  Dwarf
//
//  Created by Alexander Grebenyuk on 13.08.13.
//  Copyright (c) 2013 Alexander Grebenyuk. All rights reserved.
//

/*! Caching protocol used by DFImageFetchManager. DFCache implements this protocol.
 */

@protocol DFImageCaching <NSObject>

/*! Returns image from memory cache.
 */
- (UIImage *)imageForKey:(NSString *)key;

/*! Calls completion block on the queue with image from disk cache. Doesn't check memory cache.
 @param key The unique key.
 @param queue Queue that is used to execute completion block on.
 @param completion Completion block that gets called on the main queue (or on your queue if queue parameter isn't NULL).
 */
- (void)imageForKey:(NSString *)key
              queue:(dispatch_queue_t)queue
         completion:(void (^)(UIImage *image))completion;

/*! Store image in either memory or disk cache (or both).
 @param image Image to store in memory cache.
 @param imageData Image data to store in disk cache.
 @param key The unique key.
 */
- (void)storeImage:(UIImage *)image
         imageData:(NSData *)imageData
            forKey:(NSString *)key;

@end
