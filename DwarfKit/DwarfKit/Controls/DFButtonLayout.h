//
//  DFButtonLayout.h
//  Dwarf
//
//  Created by Alexander Grebenyuk on 7/14/13.
//  Copyright (c) 2013 Alexander Grebenyuk. All rights reserved.
//

#import <Foundation/Foundation.h>

@class DFButton;


@protocol DFButtonLayout <NSObject>

- (void)layoutButtonSubviews:(DFButton *)button;

@optional

- (CGSize)button:(DFButton *)button sizeThatFits:(CGSize)size defaultSize:(CGSize)size;

@end



@interface DFButtonLayoutVertical : NSObject <DFButtonLayout>

@property (nonatomic) CGFloat spacing;
@property (nonatomic) BOOL isImageAbove; // NO by default

@end
