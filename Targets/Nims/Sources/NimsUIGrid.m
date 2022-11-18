//
//  NimsUIGrid.m
//  Nims
//
//  Created by Yevhenii Matviienko on 12.11.2022.
//  Copyright © 2022 foxacid7cd. All rights reserved.
//

#import "NimsUIGrid.h"

@implementation NimsUIGrid {
  NimsFont *_font;
  GridRect _frame;
  GridSize _outerGridSize;
  NSMutableArray<NimsUIGridRow *> *_rows;
  CGRect _layerFrame;
}

- (instancetype)initWithFont:(NimsFont *)font frame:(GridRect)frame andOuterGridSize:(GridSize)outerGridSize
{
  self = [super init];
  if (self != nil) {
    self->_font = font;
    self->_frame = frame;
    self->_outerGridSize = outerGridSize;
    self->_rows = [[NSArray array] mutableCopy];
    
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

- (void)setFrame:(GridRect)frame andOuterGridSize:(GridSize)outerGridSize
{
  self->_frame = frame;
  
  for (NimsUIGridRow *row in self->_rows) {
    [row setGridSize:frame.size];
  }
  
  [self addAdditionalRowsIfNeeded];
  [self updateLayerFrame];
}

- (CGRect)layerFrame
{
  return self->_layerFrame;
}

- (NSArray<NimsUIGridRow *> *)rows
{
  return self->_rows;
}

- (void)addAdditionalRowsIfNeeded
{
  int64_t additionalRowsNeededCount = MAX(0, self->_frame.size.height - [self->_rows count]);
  for (int64_t i = 0; i < additionalRowsNeededCount; i++) {
    id row = [[NimsUIGridRow alloc] initWithFont:self->_font
                                        gridSize:self->_frame.size
                                        andIndex:[self->_rows count]];
    [self->_rows addObject:row];
  }
}

- (void)updateLayerFrame
{
  CGSize cellSize = [self->_font cellSize];
  GridRect frame = self->_frame;
  
  self->_layerFrame = CGRectMake(cellSize.width * frame.origin.x,
                                 cellSize.height * (self->_outerGridSize.height - frame.origin.y - frame.size.height),
                                 cellSize.width * frame.size.width,
                                 cellSize.height * frame.size.height);
}

@end
