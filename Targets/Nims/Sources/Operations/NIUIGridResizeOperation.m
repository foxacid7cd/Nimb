//
//  NIUIGridResizeOperation.m
//  Nims
//
//  Created by Yevhenii Matviienko on 19.11.2022.
//  Copyright © 2022 foxacid7cd. All rights reserved.
//

#import "NimsUIGrid.h"
#import "NIUIGridResizeOperation.h"

@implementation NIUIGridResizeOperation {
  NIUIContext *_context;
  NSNumber *_gridID;
  GridSize _size;
}

- (instancetype)initWithContext:(NIUIContext *)context
                         gridID:(NSNumber *)gridID
                           size:(GridSize)size
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
  NimsUIGrid *grid = [_context gridWithID:_gridID];
  if (grid == nil) {
    grid = [[NimsUIGrid alloc] initWithAppearance:[_context appearance]
                                            origin:GridPointZero
                                              size:_size
                                     outerGridSize:[_context outerGridSize]
                                         zPosition:[_context nextGridZPosition]];
    [_context setGrid:grid forID:_gridID];
    
  } else {
    [grid setSize:_size];
    [grid setHidden:false];
  }
  
  [_context markDirtyGridWithID:_gridID];
}

@end
