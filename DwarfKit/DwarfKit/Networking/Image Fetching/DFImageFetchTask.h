//
//  DFImageFetchOperation.h
//  Dwarf
//
//  Created by Alexander Grebenyuk on 7/16/13.
//  Copyright (c) 2013 Alexander Grebenyuk. All rights reserved.
//

#import "DFImageCaching.h"
#import "DFNetworkingConstants.h"
#import "DFTask.h"


@interface DFImageFetchTask : DFTask

/*! Image URL image fetch task was initialized with.
 */
@property (nonatomic, strong, readonly) NSString *imageURL;

#pragma mark - Task Settings

/*! Cached used by image fetch task. If cache is nil then shared NSURLCache is used instead.
 @discussion Task is set by DFImageFetchManager. But you can change cache for any particular task.
 */
@property (nonatomic, strong) id<DFImageCaching> cache;

@property (nonatomic, copy) NSURLRequest *(^requestBlock)(NSString *, DFImageFetchTask *);
- (void)setRequestBlock:(NSURLRequest *(^)(NSString *imageURL, DFImageFetchTask *task))requestBlock;

#pragma mark - Task Output

@property (nonatomic, strong, readonly) UIImage *image;

/*! Source becomes invalid (is always DFResponseSourceWeb) when NSURLCache is used as a caching mechanism. Be aware. 
 */
@property (nonatomic, readonly) DFResponseSource source;
@property (nonatomic, strong, readonly) NSError *error;

- (id)initWithURL:(NSString *)imageURL;



@end
