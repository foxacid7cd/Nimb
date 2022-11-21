//
//  NIUIGridResizeOperation.m
//  Nims
//
//  Created by Yevhenii Matviienko on 19.11.2022.
//  Copyright © 2022 foxacid7cd. All rights reserved.
//

#import "NimsUIGrid.h"
#import "NIUIGridResizeOperation.h"

@implementation NIUIGridResizeOperation{
  NIUIContext *_context;
  NSUInteger _gridID;
  NIGridSize _size;
}

- (instancetype)initWithContext:(NIUIContext *)context
                         gridID:(NSUInteger)gridID
                           size:(NIGridSize)size
{
  self = [super init];

  if (self != nil) {
    _context = context;
    _gridID = gridID;
    _size = size;
  }

  return self;
}

- (void)main
{
  NIUIGrid *grid = [_context gridForID:_gridID];

  if (grid == nil) {
    grid = [[NIUIGrid alloc] initWithAppearance:[_context appearance]
                                     superlayer:[_context mainLayer]];
    [_context setGrid:grid forID:_gridID];
  }

  [grid setSize:_size];

  if (_gridID == 0 || _gridID == 1) {
    [grid setHidden:false];
  }
}

@end
