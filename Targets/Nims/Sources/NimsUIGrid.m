//
//  NimsUIGrid.m
//  Nims
//
//  Created by Yevhenii Matviienko on 12.11.2022.
//  Copyright © 2022 foxacid7cd. All rights reserved.
//

#import "NimsUIGrid.h"

@implementation NimsUIGrid {
  NimsUIHighlights *_highlights;
  NimsFont *_font;
  GridPoint _origin;
  GridSize _size;
  NimsUIGridAnchor _anchor;
  GridSize _outerGridSize;
  NSMutableArray<NimsUIGridRow *> *_rows;
  CGRect _layerFrame;
}

- (instancetype)initWithHighlights:(NimsUIHighlights *)highlights
                              font:(NimsFont *)font
                            origin:(GridPoint)origin
                              size:(GridSize)size
                  andOuterGridSize:(GridSize)outerGridSize
{
  self = [super init];
  if (self != nil) {
    self->_highlights = highlights;
    self->_font = font;
    self->_origin = origin;
    self->_size = size;
    self->_outerGridSize = outerGridSize;
    self->_rows = [@[] mutableCopy];
    
    [self addAdditionalRowsIfNeeded];
    [self updateLayerFrame];
  }
  return self;
}

- (void)setFont:(NimsFont *)font
{
  self->_font = font;
  
  for (NimsUIGridRow *row in self->_rows) {
    [row setFont:font];
  }
  
  [self updateLayerFrame];
}

- (void)setOrigin:(GridPoint)origin
{
  self->_origin = origin;
  
  [self updateLayerFrame];
}

- (GridPoint)origin
{
  return self->_origin;
}

- (void)setSize:(GridSize)size
{
  self->_size = size;
  
  for (NimsUIGridRow *row in self->_rows) {
    [row setGridSize:size];
  }
  
  [self addAdditionalRowsIfNeeded];
  [self updateLayerFrame];
}

- (GridSize)size
{
  return self->_size;
}

- (void)setOuterGridSize:(GridSize)outerGridSize
{
  self->_outerGridSize = outerGridSize;
  
  [self updateLayerFrame];
}

- (void)setNvimAnchor:(nvim_string_t)cAnchor
{
  id anchor = [NSString stringWithCString:cAnchor.data
                                 encoding:NSUTF8StringEncoding];
  if ([anchor isEqualToString:@"NW"]) {
    self->_anchor = NimsUIGridAnchorTopLeft;
    
  } else if ([anchor isEqualToString:@"NE"]) {
    self->_anchor = NimsUIGridAnchorTopRight;
    
  } else if ([anchor isEqualToString:@"SW"]) {
    self->_anchor = NimsUIGridAnchorBottomLeft;
    
  } else if ([anchor isEqualToString:@"SE"]) {
    self->_anchor = NimsUIGridAnchorBottomRight;
    
  } else {
    NSLog(@"Unknown anchor value set in NimsUIGrid: %@", anchor);
  }
}

- (void)highlightsUpdated
{
  for (NimsUIGridRow *row in self->_rows) {
    [row highlightsUpdated];
  }
}

- (GridRect)frame
{
  GridPoint origin;
  switch (self->_anchor) {
    case NimsUIGridAnchorTopLeft:
      origin = self->_origin;
      break;
      
    case NimsUIGridAnchorTopRight:
      origin = GridPointMake(self->_origin.x - self->_size.width,
                             self->_origin.y);
      break;
      
    case NimsUIGridAnchorBottomLeft:
      origin = GridPointMake(self->_origin.x,
                             self->_origin.y - self->_size.height);
      break;
      
    case NimsUIGridAnchorBottomRight:
      origin = GridPointMake(self->_origin.x - self->_size.width,
                             self->_origin.y - self->_size.height);
      break;
      
    default:
      origin = self->_origin;
      break;
  }
  
  return GridRectMake(origin, self->_size);
}

- (CGRect)layerFrame
{
  return self->_layerFrame;
}

- (NSColor *)backgroundColor
{
  return [[self->_highlights defaultAttributes] rgbBackgroundColor];
}

- (NSArray<NimsUIGridRow *> *)rows
{
  return self->_rows;
}

- (void)addAdditionalRowsIfNeeded
{
  int64_t additionalRowsNeededCount = MAX(0, self->_size.height - [self->_rows count]);
  for (int64_t i = 0; i < additionalRowsNeededCount; i++) {
    id row = [[NimsUIGridRow alloc] initWithHighlights:self->_highlights
                                                  font:self->_font
                                              gridSize:self->_size
                                              andIndex:[self->_rows count]];
    [self->_rows addObject:row];
  }
}

- (void)updateLayerFrame
{
  CGSize cellSize = [self->_font cellSize];
  GridRect frame = [self frame];
  
  self->_layerFrame = CGRectMake(cellSize.width * frame.origin.x,
                                 cellSize.height * (self->_outerGridSize.height - frame.origin.y - frame.size.height),
                                 cellSize.width * frame.size.width,
                                 cellSize.height * frame.size.height);
}

@end
