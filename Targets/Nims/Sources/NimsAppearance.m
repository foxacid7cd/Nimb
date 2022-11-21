//
//  NimsAppearance.m
//  Nims
//
//  Created by Yevhenii Matviienko on 18.11.2022.
//  Copyright © 2022 foxacid7cd. All rights reserved.
//

#import "nvims.h"
#import "NimsAppearance.h"
#import "NSAttributedString+NimsUI.h"
#import "NSColor+NimsUI.h"

@implementation NimsAppearance {
  NSFont *_regularFont;

  NSMutableArray<HighlightAttributes *> *_attributes;
  int32_t _default_rgb_fg;
  int32_t _default_rgb_bg;
  int32_t _default_rgb_sp;

  CGSize _cellSize;
  NSFont *_boldFont;
  NSFont *_italicFont;
  NSFont *_boldItalicFont;

  NSColor *_defaultRGBForegroundColor;
  NSColor *_defaultRGBBackgroundColor;
  NSColor *_defaultRGBSpecialColor;
}

+ (NSNumber *)defaultHighlightID
{
  return [NSNumber numberWithInt:0];
}

- (instancetype)initWithFont:(NSFont *)font
{
  self = [super init];

  if (self != nil) {
    self->_attributes = [@[] mutableCopy];
    self->_default_rgb_fg = -1;
    self->_default_rgb_bg = -1;
    self->_default_rgb_sp = -1;

    [self setFont:font];
  }

  return self;
}

- (void)setFont:(NSFont *)font
{
  self->_regularFont = font;

  [self updateCellSize];
  [self updateFontVariants];
}

- (CGSize)cellSize
{
  return self->_cellSize;
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

- (void)applyAttrDefineForHighlightID:(NSUInteger)highlightID
                            rgb_attrs:(nvim_hl_attrs_t)rgb_attrs
{
  int64_t additionalAttributesNeededCount = MAX(0, highlightID - [self->_attributes count] + 1);

  for (int64_t i = 0; i < additionalAttributesNeededCount; i++) {
    id attributes = [[HighlightAttributes alloc] init];
    [self->_attributes addObject:attributes];
  }
}

- (NSDictionary<NSAttributedStringKey, id> *)stringAttributesForHighlightID:(NSUInteger)highlightID; {
  return @{
    HighlightIDAttributeName: [NSNumber numberWithUnsignedInteger:highlightID],
    NSFontAttributeName: [self fontForHighlightID:highlightID],
    NSForegroundColorAttributeName: [self foregroundColorForHighlightID:highlightID],
    NSBackgroundColorAttributeName: [NSColor systemCyanColor],
    NSLigatureAttributeName: [NSNumber numberWithInt:2]
  };
}

- (NSFont *)fontForHighlightID:(NSUInteger)highlightID
{
  if (highlightID == 0 || highlightID >= [self->_attributes count]) {
    return self->_regularFont;
  }

  id attributes = [self->_attributes objectAtIndex:highlightID];

  if ([attributes isBold]) {
    if ([attributes isItalic]) {
      return self->_boldItalicFont;
    } else {
      return self->_boldFont;
    }
  } else {
    if ([attributes isItalic]) {
      return self->_italicFont;
    } else {
      return self->_regularFont;
    }
  }
}

- (NSColor *)foregroundColorForHighlightID:(NSUInteger)highlightID
{
  if (highlightID == 0 || highlightID >= [self->_attributes count]) {
    return [self defaultRGBForegroundColor];
  }

  id attributes = self->_attributes[highlightID];

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

- (NSColor *)backgroundColorForHighlightID:(NSUInteger)highlightID
{
  if (highlightID == 0 || highlightID >= [self->_attributes count]) {
    return [self defaultRGBBackgroundColor];
  }

  id attributes = self->_attributes[highlightID];

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

- (NSColor *)specialColorForHighlightID:(NSUInteger)highlightID
{
  if (highlightID == 0 || highlightID >= [self->_attributes count]) {
    return [self defaultRGBSpecialColor];
  }

  id attributes = self->_attributes[highlightID];

  id color = [attributes rgbSpecialColor];

  if (color == nil) {
    return [self defaultRGBSpecialColor];
  }

  return color;
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

- (void)updateCellSize
{
  unichar *characters = malloc(sizeof(unichar));

  [@"M" getCharacters:characters];

  CGGlyph *glyphs = malloc(sizeof(CGGlyph));
  CGSize *advances = malloc(sizeof(CGSize));

  CTFontRef ctFont = (__bridge CTFontRef)self->_regularFont;
  CTFontGetGlyphsForCharacters(ctFont, characters, glyphs, 1);
  CTFontGetAdvancesForGlyphs(ctFont, kCTFontOrientationHorizontal, glyphs, advances, 1);
  double width = advances[0].width;

  double ascent = CTFontGetAscent(ctFont);
  double descent = CTFontGetDescent(ctFont);
  double leading = CTFontGetLeading(ctFont);
  double height = ascent + descent + leading;

  free(characters);
  free(glyphs);
  free(advances);

  CGSize cellSize = CGSizeMake(width, height);
  self->_cellSize = cellSize;
}

- (void)updateFontVariants
{
  id fontManager = [NSFontManager sharedFontManager];

  self->_boldFont = [fontManager convertFont:self->_regularFont toHaveTrait:NSFontBoldTrait];
  self->_italicFont = [fontManager convertFont:self->_regularFont toHaveTrait:NSFontItalicTrait];
  self->_boldItalicFont = [fontManager convertFont:self->_boldFont toHaveTrait:NSFontItalicTrait];
}

@end
