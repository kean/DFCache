//
//  SEImagesStressTestTableCell.m
//  Dwarf
//
//  Created by Alexander Grebenyuk on 8/12/13.
//  Copyright (c) 2013 Alexander Grebenyuk. All rights reserved.
//

#import "SDFImagesStressTestTableCell.h"
#import "SDFImageView.h"


@implementation SDFImagesStressTestTableCell {
    NSMutableArray *_imageViews;
}

- (id)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier {
    if (self = [super initWithStyle:style reuseIdentifier:reuseIdentifier]) {
        _imageViews = [NSMutableArray new];
        for (NSUInteger i = 0; i < 16; i++) {
            CGRect rect = CGRectMake(2.f + 20.f * i, 2.f, 18.f, 18.f);
            SDFImageView *imageView = [[SDFImageView alloc] initWithFrame:rect];
            imageView.contentMode = UIViewContentModeScaleAspectFill;
            imageView.clipsToBounds = YES;
            [self addSubview:imageView];
            [_imageViews addObject:imageView];
        }
    }
    return self;
}

@end
