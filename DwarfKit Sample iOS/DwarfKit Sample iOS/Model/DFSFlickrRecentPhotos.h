//
//  SEFlickrResentPhotos.h
//  Dwarf
//
//  Created by Alexander Grebenyuk on 8/12/13.
//  Copyright (c) 2013 Alexander Grebenyuk. All rights reserved.
//

#import <Foundation/Foundation.h>


@interface DFSFlickrRecentPhotos : NSObject

@property (nonatomic, strong) NSArray *photos;
@property (nonatomic) BOOL isLoaded;

- (void)loadPhotosWithPageCount:(NSUInteger)pageCount completion:(void (^)(void))completion;

@end
