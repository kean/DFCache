//
//  FlickrPhoto.m
//  Dwarf
//
//  Created by Alexander Grebenyuk on 8/11/13.
//  Copyright (c) 2013 Alexander Grebenyuk. All rights reserved.
//

#import "DFSFlickrPhoto.h"

@implementation DFSFlickrPhoto

- (id)initWithJSON:(id)JSON {
    if (self = [super init]) {
        self.farm = [JSON valueForKey:@"farm"];
        self.itemid = [JSON valueForKey:@"id"];
        self.isfamily = [JSON valueForKey:@"isfamily"];
        self.isfriend = [JSON valueForKey:@"isfriend"];
        self.ispublic = [JSON valueForKey:@"ispublic"];
        self.owner = [JSON valueForKey:@"owner"];
        self.secret = [JSON valueForKey:@"secret"];
        self.server = [JSON valueForKey:@"server"];
        self.title = [JSON valueForKey:@"title"];
        // http://farm{farm-id}.staticflickr.com/{server-id}/{id}_{secret}.jpg
        self.photoURL = [NSString stringWithFormat:@"http://farm%@.staticflickr.com/%@/%@_%@_m.jpg", self.farm, self.server, self.itemid, self.secret];
        self.photoURLSmall = [NSString stringWithFormat:@"http://farm%@.staticflickr.com/%@/%@_%@_s.jpg", self.farm, self.server, self.itemid, self.secret];
    }
    return self;
}

@end
