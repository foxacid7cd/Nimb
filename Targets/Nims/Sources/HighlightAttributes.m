//
//  HighlightAttributes.m
//  Nims
//
//  Created by Yevhenii Matviienko on 18.11.2022.
//  Copyright © 2022 foxacid7cd. All rights reserved.
//

#import "HighlightAttributes.h"

@implementation HighlightAttributes {
  nvim_hl_attr_flags_t _flags;
  nvim_rgb_value_t _rgbForeground;
  nvim_rgb_value_t _rgbBackground;
  nvim_rgb_value_t _rgbSpecial;
  int _ctermForeground;
  int _ctermBackground;
  int _blend;
  
  NSColor *_rgbForegroundColor;
  NSColor *_rgbBackgroundColor;
  NSColor *_rgbSpecialColor;
  NSColor *_ctermForegroundColor;
  NSColor *_ctermBackgroundColor;
}

- (instancetype)initWithFlags:(nvim_hl_attr_flags_t)flags
                 rgbForegound:(nvim_rgb_value_t)rgbForeground
                rgbBackground:(nvim_rgb_value_t)rgbBackground
                   rgbSpecial:(nvim_rgb_value_t)rgbSpecial
              ctermForeground:(int)ctermForeground
              ctermBackground:(int)ctermBackground
                        blend:(int)blend
{
  self = [super init];
  if (self != nil) {
    self->_flags = flags;
    self->_rgbForeground = rgbForeground;
    self->_rgbBackground = rgbBackground;
    self->_rgbSpecial = rgbSpecial;
    self->_ctermForeground = ctermForeground;
    self->_ctermBackground = ctermBackground;
    self->_blend = blend;
  }
  return self;
}

- (NSColor *)rgbForegroundColor
{
  if (self->_rgbForegroundColor == nil) {
    self->_rgbForegroundColor = [self colorFromRGBValue:self->_rgbForeground
                                               andAlpha:1];
  }
  return self->_rgbForegroundColor;
}

- (NSColor *)rgbBackgroundColor
{
  if (self->_rgbBackgroundColor == nil) {
    self->_rgbBackgroundColor = [self colorFromRGBValue:self->_rgbBackground
                                               andAlpha:1];
  }
  
  return self->_rgbBackgroundColor;
}

- (NSColor *)rgbSpecialColor
{
  if (self->_rgbSpecialColor == nil) {
    self->_rgbSpecialColor = [self colorFromRGBValue:self->_rgbSpecial
                                            andAlpha:1];
  }
  return self->_rgbSpecialColor;
}

- (NSColor *)ctermForegroundColor
{
  if (self->_ctermForegroundColor == nil) {
    self->_ctermForegroundColor = [self colorFromRGBValue:self->_ctermForeground
                                                andAlpha:1];
  }
  return self->_ctermForegroundColor;
}

- (NSColor *)ctermBackgroundColor
{
  if (self->_ctermBackgroundColor == nil) {
    self->_ctermBackgroundColor = [self colorFromRGBValue:self->_ctermBackground
                                                 andAlpha:1];
  }
  return self->_ctermBackgroundColor;
}

- (NSColor *)colorFromRGBValue:(nvim_rgb_value_t)rgbValue
                      andAlpha:(CGFloat)alpha
{
  return [NSColor colorWithRed:((rgbValue & 0xFF0000) >> 16) / 255.0
                         green:((rgbValue & 0xFF00) >> 8) / 255.0
                          blue:(rgbValue & 0xFF) / 255.0
                         alpha:alpha];
}

@end
