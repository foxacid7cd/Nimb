//
//  NimsUIGridRow.m
//  Nims
//
//  Created by Yevhenii Matviienko on 12.11.2022.
//  Copyright © 2022 foxacid7cd. All rights reserved.
//

#import <QuartzCore/QuartzCore.h>
#import "NimsUIGridRow.h"

@implementation NimsUIGridRow {
  NimsUIHighlights *_highlights;
  NimsFont *_font;
  NSParagraphStyle *_paragraphStyle;
  GridSize _gridSize;
  NSInteger _index;
  NSMutableAttributedString *_attributedString;
  CGRect _layerFrame;
}

+ (NSAttributedStringKey)highlightIDAttriubuteName
{
  return @"NimsUIGridRow.highlightIDKey";
}

- (instancetype)initWithHighlights:(NimsUIHighlights *)highlights
                              font:(NimsFont *)font
                          gridSize:(GridSize)gridSize
                          andIndex:(NSInteger)index
{
  self = [super init];
  if (self != nil) {
    self->_highlights = highlights;
    self->_font = font;
    self->_gridSize = gridSize;
    self->_index = index;
    self->_attributedString = [[NSMutableAttributedString alloc] initWithString:@""];
    
    [self updateLayerFrame];
    [self updateAttributedString];
  }
  return self;
}

- (void)setFont:(NimsFont *)font
{
  self->_font = font;
  self->_attributedString = [[NSMutableAttributedString alloc] initWithString:@""];
  
  [self updateLayerFrame];
  [self updateAttributedString];
}

- (void)setGridSize:(GridSize)gridSize
{
  self->_gridSize = gridSize;
  
  [self updateLayerFrame];
  [self updateAttributedString];
}

- (void)setIndex:(NSInteger)index
{
  self->_index = index;
  
  [self updateLayerFrame];
}

- (void)applyChangedText:(NSString *)text withHighlightID:(int64_t)highlightID startingAtX:(int64_t)x
{
  HighlightAttributes *highlightAttributes = [self->_highlights attributesForID:highlightID];
  if (highlightAttributes == nil) {
    highlightAttributes = [self->_highlights defaultAttributes];
  }
  
  NSFont *font;
  if ([highlightAttributes isBold]) {
    if ([highlightAttributes isItalic]) {
      font = [self->_font boldItalic];
      
    } else {
      font = [self->_font bold];
    }
    
  } else {
    if ([highlightAttributes isItalic]) {
      font = [self->_font italic];
      
    } else {
      font = [self->_font regular];
    }
  }
  
  id attributes = @{
    [NimsUIGridRow highlightIDAttriubuteName]:[NSNumber numberWithLongLong:highlightID],
    NSFontAttributeName:font,
    NSParagraphStyleAttributeName:[self->_font paragraphStyle],
    NSLigatureAttributeName:[NSNumber numberWithInt:2],
    NSForegroundColorAttributeName: [highlightAttributes rgbForegroundColor],
    NSBackgroundColorAttributeName: [highlightAttributes rgbBackgroundColor]
  };
  NSAttributedString *attributedString = [[NSAttributedString alloc] initWithString:text
                                                                         attributes:attributes];
  
  [self->_attributedString replaceCharactersInRange:NSMakeRange(x, [text length])
                               withAttributedString:attributedString];
}

- (void)clearText
{
  self->_attributedString = [[NSMutableAttributedString alloc] initWithString:@""];
  
  [self updateAttributedString];
}

- (void)highlightsUpdated
{
  NSRange range = NSMakeRange(0, [self->_attributedString length]);
  [self->_attributedString enumerateAttributesInRange:range options:0 usingBlock:^(NSDictionary<NSAttributedStringKey, id> *attrs, NSRange range, BOOL *stop) {
    id newAttrs = [NSMutableDictionary dictionaryWithDictionary:attrs];
    BOOL highlightAttributesSet = false;
    
    NSNumber *highlightID = [attrs objectForKey:[NimsUIGridRow highlightIDAttriubuteName]];
    if (highlightID != nil) {
      HighlightAttributes *newAttributes = [self->_highlights attributesForID:[highlightID longLongValue]];
      if (newAttributes != nil) {
        [newAttrs setObject:[newAttributes rgbForegroundColor] forKey:NSForegroundColorAttributeName];
        [newAttrs setObject:[newAttributes rgbBackgroundColor] forKey:NSBackgroundColorAttributeName];
        highlightAttributesSet = true;
      }
    }
    
    if (!highlightAttributesSet) {
      [newAttrs setObject:[[self->_highlights defaultAttributes] rgbForegroundColor] forKey:NSForegroundColorAttributeName];
      [newAttrs setObject:[[self->_highlights defaultAttributes] rgbBackgroundColor] forKey:NSBackgroundColorAttributeName];
    }
    [self->_attributedString setAttributes:newAttrs range:range];
  }];
}

- (CGRect)layerFrame
{
  return self->_layerFrame;
}

- (NSAttributedString *)attributedString
{
  return self->_attributedString;
}

- (void)updateLayerFrame
{
  CGSize cellSize = [self->_font cellSize];
  self->_layerFrame = CGRectMake(0,
                                 cellSize.height * (self->_gridSize.height - self->_index - 1),
                                 cellSize.width * self->_gridSize.width,
                                 cellSize.height);
}

- (void)updateAttributedString
{
  int64_t additionalStringLength = MAX(0, self->_gridSize.width - [self->_attributedString length]);
  if (additionalStringLength > 0) {
    id additionalString = [@"" stringByPaddingToLength:additionalStringLength
                                            withString:@" "
                                       startingAtIndex:0];
    id attributes = @{
      NSFontAttributeName:[self->_font regular],
      NSForegroundColorAttributeName:[[self->_highlights defaultAttributes] rgbForegroundColor],
      NSBackgroundColorAttributeName:[[self->_highlights defaultAttributes] rgbBackgroundColor],
      NSParagraphStyleAttributeName:[self->_font paragraphStyle],
      NSLigatureAttributeName:[NSNumber numberWithInt:2]
    };
    id additionalAttributedString = [[NSAttributedString alloc] initWithString:additionalString
                                                                    attributes:attributes];
    
    [self->_attributedString appendAttributedString:additionalAttributedString];
  }
}

@end
