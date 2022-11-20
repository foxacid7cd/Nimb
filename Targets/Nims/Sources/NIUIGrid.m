//
//  NIUIGrid.m
//  Nims
//
//  Created by Yevhenii Matviienko on 20.11.2022.
//  Copyright © 2022 foxacid7cd. All rights reserved.
//

#import "NIUIGrid.h"

@implementation NIUIGrid {
  nvim_grid_cell_t **_rows;
}

- (instancetype)initWithSize:(NIGridSize)size
{
  self = [super init];
  if (self != nil) {
    [self setSize:size];
  }
  return self;
}

- (void)dealloc
{
  [NIUIGrid freeRows:_rows withSize:_size];
}

- (void)setSize:(NIGridSize)size
{
  nvim_grid_cell_t **rows = [NIUIGrid createRowsWithSize:size];
  [NIUIGrid copyRows:_rows withSize:_size toRows:rows withSize:size];
  
  _size = size;
  _rows = rows;
}

- (void)applyRawLineAtGridY:(NSInteger)gridY
                 startGridX:(NSInteger)startGridX
                   endGridX:(NSInteger)endGridX
                 clearGridX:(NSInteger)clearGridX
             clearAttribute:(NSNumber *)clearAttribute
                      flags:(NSInteger)flags
                      chunk:(nvim_schar_t *)chunk
                 attributes:(nvim_sattr_t *)attributes;
{
  NSInteger length = endGridX - startGridX;
  for (NSInteger i = 0; i < length; i++) {
    memcpy(&_rows[gridY][i + startGridX].data, chunk[i], sizeof(nvim_schar_t));
    _rows[gridY][i + startGridX].attr = attributes[i];
  }
}


+ (nvim_grid_cell_t **)createRowsWithSize:(NIGridSize)size
{
  nvim_grid_cell_t **rows = malloc(sizeof(nvim_grid_cell_t *) * size.height);
  
  for (NSInteger gridY = 0; gridY < size.height; gridY++) {
    size_t rowSize = sizeof(nvim_grid_cell_t) * size.width;
    
    rows[gridY] = malloc(rowSize);
    memset(rows[gridY], 0, rowSize);
  }
  
  return rows;
}

+ (void)copyRows:(nvim_grid_cell_t **)srcRows
        withSize:(NIGridSize)srcSize
          toRows:(nvim_grid_cell_t **)dstRows
        withSize:(NIGridSize)dstSize
{
  NIGridSize size = NIGridSizeMake(MIN(srcSize.width, dstSize.width),
                                   MIN(srcSize.height, dstSize.height));
  
  for (NSInteger gridY = 0; gridY < size.height; gridY++) {
    memcpy(dstRows[gridY], srcRows[gridY], size.width);
  }
}

+ (void)freeRows:(nvim_grid_cell_t **)rows withSize:(NIGridSize)size
{
  for (NSInteger gridY = 0; gridY < size.height; gridY++) {
    free(rows[gridY]);
  }
  
  free(rows);
}

@end
