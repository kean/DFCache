//
//  SEDFImageFetchManager.h
//  Dwarf
//
//  Created by Alexander Grebenyuk on 8/12/13.
//  Copyright (c) 2013 Alexander Grebenyuk. All rights reserved.
//

#import "DFImageFetchManager.h"


@interface SDFImageFetchManager : DFImageFetchManager

+ (instancetype)sharedStressTestManager;

@property (nonatomic) NSUInteger imageRequestCount;
@property (nonatomic) NSUInteger imageRequestCancelCount;

@end
