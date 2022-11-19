//
//  NimsUIHighlights.m
//  Nims
//
//  Created by Yevhenii Matviienko on 18.11.2022.
//  Copyright © 2022 foxacid7cd. All rights reserved.
//

#import "NSColor+NimsUI.h"
#import "NimsUIHighlights.h"

@implementation NimsUIHighlights {
  NSMutableArray<HighlightAttributes *> *_attributes;
  int32_t _default_rgb_fg;
  int32_t _default_rgb_bg;
  int32_t _default_rgb_sp;
  
  NSColor *_defaultRGBForegroundColor;
  NSColor *_defaultRGBBackgroundColor;
  NSColor *_defaultRGBSpecialColor;
}

- (instancetype)init
{
  self = [super init];
  if (self != nil) {
    self->_attributes = [@[] mutableCopy];
    self->_default_rgb_fg = -1;
    self->_default_rgb_bg = -1;
    self->_default_rgb_sp = -1;
  }
  return self;
}

- (void)applyDefaultColorsSetWithRGB_fg:(int32_t)rgb_fg
                                 rgb_bg:(int32_t)rgb_bg
                                 rgb_sp:(int32_t)rgb_sp
{
  self->_default_rgb_fg = rgb_fg;
  self->_default_rgb_bg = rgb_bg;
  self->_default_rgb_sp = rgb_sp;
  
  self->_defaultRGBForegroundColor = nil;
  self->_defaultRGBBackgroundColor = nil;
  self->_defaultRGBSpecialColor = nil;
}

- (void)applyAttrDefineForHighlightID:(NSNumber *)highlightID
                            rgb_attrs:(nvim_hl_attrs_t)rgb_attrs
{
  int64_t additionalAttributesNeededCount = MAX(0, [highlightID longLongValue] - [self->_attributes count] + 1);
  for (int64_t i = 0; i < additionalAttributesNeededCount; i++) {
    id attributes = [[HighlightAttributes alloc] init];
    [self->_attributes addObject:attributes];
  }
  
  id attributes = [self->_attributes objectAtIndex:[highlightID longLongValue]];
  [attributes applyAttrDefineWithRGBAttrs:rgb_attrs];
}

- (NSColor *)foregroundColorForHighlightID:(NSNumber *)highlightID
{
  int64_t index = [highlightID longLongValue];
  
  if (index >= [self->_attributes count]) {
    return [self defaultRGBForegroundColor];
  }
  
  id attributes = [self->_attributes objectAtIndex:index];
  
  NSColor *color;
  if ([attributes isInversed]) {
    color = [attributes rgbBackgroundColor];
    
  } else {
    color = [attributes rgbForegroundColor];
  }
  
  if (color == nil) {
    return [self defaultRGBForegroundColor];
  }
  
  return color;
}

- (NSColor *)backgroundColorForHighlightID:(NSNumber *)highlightID
{
  int64_t index = [highlightID longLongValue];
  
  if (index >= [self->_attributes count]) {
    return [self defaultRGBBackgroundColor];
  }
  
  id attributes = [self->_attributes objectAtIndex:index];
  
  NSColor *color;
  if ([attributes isInversed]) {
    color = [attributes rgbForegroundColor];
    
  } else {
    color = [attributes rgbBackgroundColor];
  }
  
  if (color == nil) {
    return [self defaultRGBBackgroundColor];
  }
  
  return color;
}

- (NSColor *)specialColorForHighlightID:(NSNumber *)highlightID
{
  int64_t index = [highlightID longLongValue];
  
  if (index >= [self->_attributes count]) {
    return [self defaultRGBSpecialColor];
  }
  
  id attributes = [self->_attributes objectAtIndex:index];
  
  id color = [attributes rgbSpecialColor];
  if (color == nil) {
    return [self defaultRGBSpecialColor];
  }
  
  return color;
}

- (NSFont *)pickFont:(NimsFont *)font forHighlightID:(NSNumber *)highlightID
{
  int64_t index = [highlightID longLongValue];
  if (index >= [self->_attributes count]) {
    return [font regular];
  }
  
  return [[self->_attributes objectAtIndex:index] pickFont:font];
}

- (NSColor *)defaultRGBForegroundColor
{
  if (self->_default_rgb_fg < 0) {
    return [NSColor whiteColor];
  }
  
  id color = self->_defaultRGBForegroundColor;
  if (color == nil) {
    color = [NSColor colorFromRGBValue:self->_default_rgb_fg alpha:1];
    self->_defaultRGBForegroundColor = color;
  }
  
  return color;
}

- (NSColor *)defaultRGBBackgroundColor
{
  if (self->_default_rgb_bg < 0) {
    return [NSColor blackColor];
  }
  
  id color = self->_defaultRGBBackgroundColor;
  if (color == nil) {
    color = [NSColor colorFromRGBValue:self->_default_rgb_bg alpha:1];
    self->_defaultRGBBackgroundColor = color;
  }
  
  return color;
}

- (NSColor *)defaultRGBSpecialColor
{
  if (self->_default_rgb_sp < 0) {
    return [NSColor cyanColor];
  }
  
  id color = self->_defaultRGBSpecialColor;
  if (color == nil) {
    color = [NSColor colorFromRGBValue:self->_default_rgb_sp alpha:1];
    self->_defaultRGBSpecialColor = color;
  }
  
  return color;
}

@end
