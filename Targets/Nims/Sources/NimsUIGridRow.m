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
  NimsFont *_font;
  NSParagraphStyle *_paragraphStyle;
  GridSize _gridSize;
  NSInteger _index;
  NSMutableAttributedString *_attributedString;
  CGRect _layerFrame;
}

- (instancetype)initWithFont:(NimsFont *)font gridSize:(GridSize)gridSize andIndex:(NSInteger)index
{
  self = [super init];
  if (self != nil) {
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

- (void)applyChangedText:(NSString *)text startingAtX:(int64_t)x
{
  id attributes = @{
    NSFontAttributeName:[self->_font font],
    NSForegroundColorAttributeName:[NSColor whiteColor],
    NSBackgroundColorAttributeName:[NSColor blackColor],
    NSParagraphStyleAttributeName:[self->_font paragraphStyle],
    NSLigatureAttributeName: [NSNumber numberWithInt:2]
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
      NSFontAttributeName:[self->_font font],
      NSBackgroundColorAttributeName:[NSColor blackColor],
      NSParagraphStyleAttributeName: [self->_font paragraphStyle],
      NSLigatureAttributeName: [NSNumber numberWithInt:2]
    };
    id additionalAttributedString = [[NSAttributedString alloc] initWithString:additionalString
                                                                    attributes:attributes];
    
    [self->_attributedString appendAttributedString:additionalAttributedString];
  }
}

@end
