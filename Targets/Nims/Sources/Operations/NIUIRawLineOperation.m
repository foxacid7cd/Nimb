//
//  NIUIRawLineOperation.m
//  Nims
//
//  Created by Yevhenii Matviienko on 19.11.2022.
//  Copyright © 2022 foxacid7cd. All rights reserved.
//

#import "NIUIRawLineOperation.h"

@implementation NIUIRawLineOperation{
  NIUIContext *_context;
  NSUInteger _gridID;
  NSInteger _gridY;
  NSInteger _startGridX;
  NSInteger _endGridX;
  NSInteger _clearGridX;
  NSUInteger _clearAttribute;
  NSInteger _flags;
  nvim_schar_t *_chunk;
  nvim_sattr_t *_attributes;
}

- (instancetype)initWithContext:(NIUIContext *)context
                         gridID:(NSUInteger)gridID
                          gridY:(NSInteger)gridY
                     startGridX:(NSInteger)startGridX
                       endGridX:(NSInteger)endGridX
                     clearGridX:(NSInteger)clearGridX
                 clearAttribute:(NSUInteger)clearAttribute
                          flags:(NSInteger)flags
                          chunk:(const nvim_schar_t *)chunk
                     attributes:(const nvim_sattr_t *)attributes
{
  self = [super init];

  if (self) {
    _context = context;
    _gridID = gridID;
    _gridY = gridY;
    _startGridX = startGridX;
    _endGridX = endGridX;
    _clearGridX = clearGridX;
    _clearAttribute = clearAttribute;
    _flags = flags;

    NSInteger length = endGridX - startGridX;

    size_t chunkSize = sizeof(nvim_schar_t) * length;
    _chunk = malloc(chunkSize);
    memcpy(_chunk, &chunk, chunkSize);

    size_t attributesSize = sizeof(nvim_sattr_t) * length;
    _attributes = malloc(attributesSize);
    memcpy(_attributes, &attributes, attributesSize);
  }

  return self;
}

- (void)dealloc
{
  free(_chunk);
  free(_attributes);
}

- (void)main
{
  NIUIGrid *grid = [_context gridForID:_gridID];

  if (grid) {
    [grid applyRawLineAtGridY:_gridY
                   startGridX:_startGridX
                     endGridX:_endGridX
                   clearGridX:_clearGridX
               clearAttribute:_clearAttribute
                        flags:_flags
                        chunk:_chunk
                   attributes:_attributes];
  }
}

@end
