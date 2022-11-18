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
  NSFont *_font;
  CGSize _cellSize;
  NSParagraphStyle *_paragraphStyle;
}

- (instancetype)initWithFont:(NSFont *)font
{
  self->_font = font;
  
  unichar *characters = malloc(sizeof(unichar));
  [@"A" getCharacters:characters];
  
  CGGlyph *glyphs = malloc(sizeof(CGGlyph));
  CGSize *advances = malloc(sizeof(CGSize));
  
  CTFontRef ctFont = (__bridge CTFontRef)self->_font;
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
  [paragraphStyle setMinimumLineHeight:height];
  [paragraphStyle setMaximumLineHeight:height];
  self->_paragraphStyle = [paragraphStyle copy];
  
  return [super init];
}

- (NSFont *)font
{
  return self->_font;
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
