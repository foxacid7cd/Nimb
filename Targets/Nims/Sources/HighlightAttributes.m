//
//  HighlightAttributes.m
//  Nims
//
//  Created by Yevhenii Matviienko on 18.11.2022.
//  Copyright © 2022 foxacid7cd. All rights reserved.
//

#import "NSColor+NimsUI.h"
#import "HighlightAttributes.h"

@implementation HighlightAttributes {
  nvim_hl_attr_flags_t _flags;
  nvim_rgb_value_t _rgbForeground;
  nvim_rgb_value_t _rgbBackground;
  nvim_rgb_value_t _rgbSpecial;
  int _blend;
  
  NSColor *_rgbForegroundColor;
  NSColor *_rgbBackgroundColor;
  NSColor *_rgbSpecialColor;
}

- (instancetype)init
{
  self = [super init];
  if (self != nil) {
    self->_rgbForeground = -1;
    self->_rgbBackground = -1;
    self->_rgbSpecial = -1;
  }
  return self;
}

- (void)applyAttrDefineWithRGBAttrs:(nvim_hl_attrs_t)rgb_attrs
{
  if (rgb_attrs.rgb_ae_attr > 0) {
    self->_flags |= rgb_attrs.rgb_ae_attr;
  }
  
  if (rgb_attrs.rgb_fg_color > 0) {
    self->_rgbForeground = rgb_attrs.rgb_fg_color;
    self->_rgbForegroundColor = nil;
  }
  
  if (rgb_attrs.rgb_bg_color > 0) {
    self->_rgbBackground = rgb_attrs.rgb_bg_color;
    self->_rgbBackgroundColor = nil;
  }
  
  if (rgb_attrs.rgb_sp_color > 0) {
    self->_rgbSpecial = rgb_attrs.rgb_sp_color;
    self->_rgbSpecialColor = nil;
  }
  
  if (rgb_attrs.hl_blend > 0) {
    self->_blend = rgb_attrs.hl_blend;
    self->_rgbBackgroundColor = nil;
  }
}

- (NSColor *)rgbForegroundColor
{
  if (self->_rgbForeground < 0) {
    return nil;
  }
  
  if (self->_rgbForegroundColor == nil) {
    self->_rgbForegroundColor = [NSColor colorFromRGBValue:self->_rgbForeground
                                                     alpha:1];
  }
  return self->_rgbForegroundColor;
}

- (NSColor *)rgbBackgroundColor
{
  if (self->_rgbBackground < 0) {
    return nil;
  }
  
  if (self->_rgbBackgroundColor == nil) {
    CGFloat alpha = 1 - ((CGFloat)self->_blend / 100.0);
    self->_rgbBackgroundColor = [NSColor colorFromRGBValue:self->_rgbBackground
                                                     alpha:alpha];
  }
  return self->_rgbBackgroundColor;
}

- (NSColor *)rgbSpecialColor
{
  if (self->_rgbSpecial < 0) {
    return nil;
  }
  
  if (self->_rgbSpecialColor == nil) {
    self->_rgbSpecialColor = [NSColor colorFromRGBValue:self->_rgbSpecial
                                                  alpha:1];
  }
  return self->_rgbSpecialColor;
}

- (BOOL)isInversed
{
  return (self->_flags & NvimHlAttrFlagsInverse) != 0;
}

- (BOOL)isBold
{
  return (self->_flags & NvimHlAttrFlagsBold) != 0;
}

- (BOOL)isItalic
{
  return (self->_flags & NvimHlAttrFlagsItalic) != 0;
}

@end
