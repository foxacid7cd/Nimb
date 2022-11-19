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
  CGFloat _zPosition;
  BOOL _isHidden;
  NSMutableArray<NimsUIGridRow *> *_rows;
  CALayer *_layer;
  NSMutableSet<NSNumber *> *_changedYs;
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
    self->_layer = [[CALayer alloc] init];
    self->_changedYs = [[NSSet set] mutableCopy];
    
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

- (void)setZPosition:(CGFloat)zPosition
{
  self->_zPosition = zPosition;
}

- (CGFloat)zPosition
{
  return self->_zPosition;
}

- (void)setHidden:(BOOL)isHidden
{
  self->_isHidden = isHidden;
  
  [self->_layer setHidden:isHidden];
}

- (BOOL)isHidden
{
  return self->_isHidden;
}

- (void)highlightsUpdated
{
  for (NimsUIGridRow *row in self->_rows) {
    [row highlightsUpdated];
  }
}

- (void)clearText
{
  [self->_rows enumerateObjectsUsingBlock:^(NimsUIGridRow *row, NSUInteger index, BOOL *stop) {
    [row clearText];
    
    [self->_changedYs addObject:[NSNumber numberWithUnsignedLong:index]];
  }];
}

- (void)applyChangedText:(NSString *)text
         withHighlightID:(NSNumber *)highlightID
             startingAtX:(int64_t)x
                    forY:(int64_t)y
{
  id row = [self->_rows objectAtIndex:y];
  [row applyChangedText:text withHighlightID:highlightID startingAtX:x];
  
  [self->_changedYs addObject:[NSNumber numberWithLongLong:y]];
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

- (void)flush
{
  for (id y in self->_changedYs) {
    id row = [self->_rows objectAtIndex:[y longLongValue]];
    [row flush];
    
    if ([[row layer] superlayer] == nil) {
      [self->_layer addSublayer:[row layer]];
    }
  }
  
  [self->_layer setFrame:self->_layerFrame];
  [self->_layer setZPosition:self->_zPosition];
  
  [self->_changedYs removeAllObjects];
}

- (CALayer *)layer
{
  return self->_layer;
}

- (void)addAdditionalRowsIfNeeded
{
  int64_t initialRowsCount = [self->_rows count];
  int64_t additionalRowsNeededCount = MAX(0, self->_size.height - initialRowsCount);
  for (int64_t i = 0; i < additionalRowsNeededCount; i++) {
    id row = [[NimsUIGridRow alloc] initWithHighlights:self->_highlights
                                                  font:self->_font
                                              gridSize:self->_size
                                              andIndex:initialRowsCount + i];
    [self->_rows addObject:row];
    
    [self->_changedYs addObject:[NSNumber numberWithLongLong:initialRowsCount + i]];
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
