//
//  DFButton.h
//  Dwarf
//
//  Created by Alexander Grebenyuk on 7/14/13.
//  Copyright (c) 2013 Alexander Grebenyuk. All rights reserved.
//

#import "DFButtonLayout.h"


@interface DFButton : UIButton

@property (nonatomic, strong) id<DFButtonLayout> buttonLayout;

- (void)setBorderColor:(UIColor *)color forState:(UIControlState)state;
- (void)setBorderWidth:(CGFloat)width forState:(UIControlState)state;
- (CGFloat)borderWidthForState:(UIControlState)state;
- (UIColor *)borderColorForState:(UIControlState)state;

@end
