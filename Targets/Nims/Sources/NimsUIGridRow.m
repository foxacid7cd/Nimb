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
  GridSize _gridSize;
  NSInteger _index;
  NSMutableAttributedString *_attributedString;
  CGRect _layerFrame;
  CATextLayer *_textLayer;
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
    self->_textLayer = [[CATextLayer alloc] init];
    
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

- (void)applyChangedText:(NSString *)text withHighlightID:(NSNumber *)highlightID startingAtX:(int64_t)x
{
  id attributes = @{
    [NimsUIGridRow highlightIDAttriubuteName]:highlightID,
    NSFontAttributeName:[self->_highlights pickFont:self->_font forHighlightID:highlightID],
    NSParagraphStyleAttributeName:[self->_font paragraphStyle],
    NSLigatureAttributeName:[NSNumber numberWithInt:0],
    NSForegroundColorAttributeName: [self->_highlights foregroundColorForHighlightID:highlightID],
    NSBackgroundColorAttributeName: [self->_highlights backgroundColorForHighlightID:highlightID]
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
      [newAttrs setObject:[self->_highlights foregroundColorForHighlightID:highlightID]
                   forKey:NSForegroundColorAttributeName];
      [newAttrs setObject:[self->_highlights backgroundColorForHighlightID:highlightID]
                   forKey:NSBackgroundColorAttributeName];
      highlightAttributesSet = true;
    }
    
    if (!highlightAttributesSet) {
      [newAttrs setObject:[self->_highlights defaultRGBForegroundColor]
                   forKey:NSForegroundColorAttributeName];
      [newAttrs setObject:[self->_highlights defaultRGBBackgroundColor]
                   forKey:NSBackgroundColorAttributeName];
    }
    
    [self->_attributedString setAttributes:newAttrs range:range];
  }];
}

- (void)flush
{
  [self->_textLayer setFrame:self->_layerFrame];
  [self->_textLayer setString:self->_attributedString];
}

- (CALayer *)layer
{
  return self->_textLayer;
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
      NSForegroundColorAttributeName:[self->_highlights defaultRGBForegroundColor],
      NSBackgroundColorAttributeName:[self->_highlights defaultRGBBackgroundColor],
      NSParagraphStyleAttributeName:[self->_font paragraphStyle],
      NSLigatureAttributeName:[NSNumber numberWithInt:0]
    };
    id additionalAttributedString = [[NSAttributedString alloc] initWithString:additionalString
                                                                    attributes:attributes];
    
    [self->_attributedString appendAttributedString:additionalAttributedString];
  }
}

@end
