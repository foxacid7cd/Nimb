//
//  NimsFont.m
//  Nims
//
//  Created by Yevhenii Matviienko on 17.11.2022.
//  Copyright © 2022 foxacid7cd. All rights reserved.
//

#import <CoreText/CoreText.h>
#import "NimsFont.h"

@implementation NimsFont {
  NSFont *_regular;
  NSFont *_bold;
  NSFont *_italic;
  NSFont *_boldItalic;
  CGSize _cellSize;
  NSParagraphStyle *_paragraphStyle;
}

- (instancetype)initWithFont:(NSFont *)font
{
  id fontManager = [NSFontManager sharedFontManager];
  
  self->_regular = font;
  self->_bold = [fontManager convertFont:self->_regular toHaveTrait:NSFontBoldTrait];
  self->_italic = [fontManager convertFont:self->_regular toHaveTrait:NSFontItalicTrait];
  self->_boldItalic = [fontManager convertFont:self->_bold toHaveTrait:NSFontItalicTrait];
  
  unichar *characters = malloc(sizeof(unichar));
  [@"M" getCharacters:characters];
  
  CGGlyph *glyphs = malloc(sizeof(CGGlyph));
  CGSize *advances = malloc(sizeof(CGSize));
  
  CTFontRef ctFont = (__bridge CTFontRef)self->_regular;
  CTFontGetGlyphsForCharacters(ctFont, characters, glyphs, 1);
  CTFontGetAdvancesForGlyphs(ctFont, kCTFontOrientationHorizontal, glyphs, advances, 1);
  double width = advances[0].width;
  
  double ascent = CTFontGetAscent(ctFont);
  double descent = CTFontGetDescent(ctFont);
  double leading = CTFontGetLeading(ctFont);
  double height = ascent + descent + leading;
  
  CGSize cellSize = CGSizeMake(width, height);
  self->_cellSize = cellSize;
  
  free(characters);
  free(glyphs);
  free(advances);
  
  id paragraphStyle = [[NSMutableParagraphStyle defaultParagraphStyle] mutableCopy];
  [paragraphStyle setLineSpacing:leading];
  self->_paragraphStyle = paragraphStyle;
  
  return [super init];
}

- (NSFont *)regular
{
  return self->_regular;
}

- (NSFont *)bold
{
  return self->_bold;
}

- (NSFont *)italic
{
  return self->_italic;
}

- (NSFont *)boldItalic
{
  return self->_boldItalic;
}

- (CGSize)cellSize
{
  return self->_cellSize;
}

- (NSParagraphStyle *)paragraphStyle
{
  return self->_paragraphStyle;
}

@end
