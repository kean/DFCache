//
//  DFButton.m
//  Dwarf
//
//  Created by Alexander Grebenyuk on 7/14/13.
//  Copyright (c) 2013 Alexander Grebenyuk. All rights reserved.
//

#import "DFButton.h"
#import <QuartzCore/QuartzCore.h>


@implementation DFButton {
   NSMutableDictionary *_borderColors;
   NSMutableDictionary *_borderWidth;
}


- (id)initWithFrame:(CGRect)frame {
   if ((self = [super initWithFrame:frame])) {
      _borderColors = [NSMutableDictionary new];
      _borderWidth = [NSMutableDictionary new];
   }
   return self;
}

#pragma mark - Custom Layout

- (void)setButtonLayout:(id<DFButtonLayout>)buttonLayout {
   _buttonLayout = buttonLayout;
   [self setNeedsLayout];
}


- (void)layoutSubviews {
   [super layoutSubviews];
   [_buttonLayout layoutButtonSubviews:self];
}


- (CGSize)sizeThatFits:(CGSize)size {
   CGSize resultSize = [super sizeThatFits:size];
   if ([_buttonLayout respondsToSelector:@selector(button:sizeThatFits:defaultSize:)]) {
      resultSize = [_buttonLayout button:self sizeThatFits:size defaultSize:resultSize];
   }
   return resultSize;
}

#pragma mark - State

- (void)setEnabled:(BOOL)enabled {
   [super setEnabled:enabled];
   [self didChangeState];
}


- (void)setHighlighted:(BOOL)highlighted {
   [super setHighlighted:highlighted];
   [self didChangeState];
}


- (void)setSelected:(BOOL)selected {
   [super setSelected:selected];
   [self didChangeState];
}


- (void)didChangeState {
   UIColor *borderColor = [self borderColorForState:self.state];
   if (borderColor) {
      self.layer.borderColor = borderColor.CGColor;
      CGFloat borderWidth = [self borderWidthForState:self.state];
      self.layer.borderWidth = borderWidth;
   }
}

#pragma mark - Border

- (void)setBorderColor:(UIColor *)color forState:(UIControlState)state {
   if (color) {
      _borderColors[@(state)] = color;
   } else {
      [_borderColors removeObjectForKey:@(state)];
   }
   if (state == self.state) {
      self.layer.borderColor = color.CGColor;
   }
}


- (void)setBorderWidth:(CGFloat)width forState:(UIControlState)state {
   _borderWidth[@(state)] = @(width);
   if (state == self.state) {
      self.layer.borderWidth = width;
   }
}


- (CGFloat)borderWidthForState:(UIControlState)state {
   NSNumber *width = _borderWidth[@(state)];
   if (width) return [width floatValue];
   width = _borderWidth[@(UIControlStateNormal)];
   if (width) return [width floatValue];
   return 0.0;
}


- (UIColor *)borderColorForState:(UIControlState)state {
   UIColor *color = _borderColors[@(state)];
   if (color) return color;
   return _borderColors[@(UIControlStateNormal)];
}

@end
