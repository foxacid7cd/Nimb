//
//  NimsUIGrid.m
//  Nims
//
//  Created by Yevhenii Matviienko on 12.11.2022.
//  Copyright © 2022 foxacid7cd. All rights reserved.
//

#import "NimsUIGridRow.h"
#import "NimsUIGrid.h"

@implementation NimsUIGrid {
  NSNumber *__id;
  NSFont *_font;
  GridSize _size;
  NSMutableArray<NimsUIGridRow *> *_rows;
  CALayer *_layer;
}

- (instancetype)initWithID:(NSNumber *)_id andFont:(NSFont *)font
{
  self->__id = _id;
  self->_font = font;
  self->_rows = [[NSArray array] mutableCopy];
  self->_layer = [[CALayer alloc] init];
  return [super init];
}

- (NSNumber *)_id {
  return self->__id;
}

- (void)setSize:(GridSize)size
{
  self->_size = size;
  
  int64_t additionalRowsNeededCount = MAX(0, size.height - [self->_rows count]);
  for (int64_t i = 0; i < additionalRowsNeededCount; i++) {
    id row = [[NimsUIGridRow alloc] initWithFont:self->_font];
    [self->_rows addObject:row];
  }
  
  NSLog(@"NimsUIGrid rows %lu", (unsigned long)[_rows count]);
}

@end
