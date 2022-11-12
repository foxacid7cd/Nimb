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
  NSNumber *_id;
  GridSize size;
  NSMutableArray<NimsUIGridRow *> *rows;
}

- (instancetype)initWithID:(NSNumber *)_id
{
  self->_id = _id;
  rows = [[NSArray array] mutableCopy];
  return [super init];
}

- (NSNumber *)_id
{
  return self->_id;
}

- (void)setSize:(GridSize)size
{
  self->size = size;
  
  int64_t rowsNeededCount = MAX(0, size.height - [self->rows count]);
  for (int64_t i = 0; i < rowsNeededCount; i++) {
    id row = [[NimsUIGridRow alloc] init];
    [self->rows addObject:row];
  }
  
  NSLog(@"NimsUIGrid rows %lu", (unsigned long)[rows count]);
}

@end
