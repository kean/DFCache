//
//  SEDFImageFetchManager.m
//  Dwarf
//
//  Created by Alexander Grebenyuk on 8/12/13.
//  Copyright (c) 2013 Alexander Grebenyuk. All rights reserved.
//

#import "SDFImageFetchManager.h"
#import "DFCache.h"


@implementation SDFImageFetchManager

+ (instancetype)sharedStressTestManager {
    static SDFImageFetchManager *shared = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        shared = [[self class] new];
        shared.cache = [[DFCache alloc] initWithName:@"df_shared_manager_cache"];
    });
    return shared;
}


- (id)init {
    if (self = [super init]) {
        self.queue.maxConcurrentTaskCount = 6;
    }
    return self;
}


- (DFImageFetchTask *)fetchImageWithURL:(NSString *)imageURL handler:(DFImageFetchHandler *)handler {
    _imageRequestCount += 1;
    return [super fetchImageWithURL:imageURL handler:handler];
}


- (void)cancelFetchingWithURL:(NSString *)imageURL handler:(DFImageFetchHandler *)handler {
    _imageRequestCancelCount += 1;
    [super cancelFetchingWithURL:imageURL handler:handler];
}

@end
