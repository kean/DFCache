//
//  FlickrPhoto.h
//  Dwarf
//
//  Created by Alexander Grebenyuk on 8/11/13.
//  Copyright (c) 2013 Alexander Grebenyuk. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface DFSFlickrPhoto : NSObject

@property (nonatomic, strong) NSString *farm;
@property (nonatomic, strong) NSString *itemid;
@property (nonatomic, strong) NSString *isfamily;
@property (nonatomic, strong) NSString *isfriend;
@property (nonatomic, strong) NSString *ispublic;
@property (nonatomic, strong) NSString *owner;
@property (nonatomic, strong) NSString *secret;
@property (nonatomic, strong) NSString *server;
@property (nonatomic, strong) NSString *title;
@property (nonatomic, strong) NSString *photoURL;
@property (nonatomic, strong) NSString *photoURLSmall;

- (id)initWithJSON:(NSDictionary *)JSON;

@end
