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
  NSMutableArray<NimsUIGridRow *> *rows;
}

- (instancetype)initWithID:(NSNumber *)_id {
  self->_id = _id;
  rows = [[NSArray array] mutableCopy];
  return [super init];
}

- (NSNumber *)_id {
  return self->_id;
}

@end
