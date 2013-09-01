//
//  DFImageView.h
//  Dwarf
//
//  Created by Alexander Grebenyuk on 8/11/13.
//  Copyright (c) 2013 Alexander Grebenyuk. All rights reserved.
//


@interface DFImageView : UIImageView

@property (nonatomic, strong) NSString *imageURL;

- (void)setImageWithURL:(NSString *)imageURL;
- (void)setImageWithURL:(NSString *)imageURL placeholder:(UIImage *)placeholder;

@end
