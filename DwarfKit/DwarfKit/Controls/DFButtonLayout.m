//
//  DFButtonLayout.m
//  Dwarf
//
//  Created by Alexander Grebenyuk on 7/14/13.
//  Copyright (c) 2013 Alexander Grebenyuk. All rights reserved.
//

#import "DFButtonLayout.h"
#import "DFButton.h"
#import "UIView+Dwarf.h"


@implementation DFButtonLayoutVertical

- (void)layoutButtonSubviews:(DFButton *)button {
   UIImageView *imageView = button.imageView;
   UILabel *titleLabel = button.titleLabel;
   
   CGSize contentSize =
   CGSizeMake(MAX(imageView.width, titleLabel.width),
              imageView.height + titleLabel.height + self.spacing);
   CGRect contentFrame =
   CGRectMake(CGRectGetMidX(button.bounds) - contentSize.width / 2.0,
              CGRectGetMidY(button.bounds) - contentSize.height / 2.0,
              contentSize.width, contentSize.height);
   
   CGRect imageFrame = imageView.frame;
   imageFrame.origin.x = CGRectGetMidX(contentFrame) - imageView.width / 2.0;
   imageFrame.origin.y = contentFrame.origin.y;
   imageView.frame = imageFrame;
   
   CGRect titleFrame = titleLabel.frame;
   titleFrame.origin.x = CGRectGetMidX(contentFrame) - titleLabel.width / 2.0;
   titleFrame.origin.y = contentFrame.size.height - titleLabel.height;
   titleLabel.frame = titleFrame;
}

@end
