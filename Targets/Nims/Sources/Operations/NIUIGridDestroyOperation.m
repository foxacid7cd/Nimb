//
//  NIUIGridDestroyOperation.m
//  Nims
//
//  Created by Yevhenii Matviienko on 21.11.2022.
//  Copyright © 2022 foxacid7cd. All rights reserved.
//

#import "NIUIContext.h"
#import "NIUIGridDestroyOperation.h"

@implementation NIUIGridDestroyOperation {
  NIUIContext *_context;
  NSInteger _gridID;
}

- (instancetype)initWithContext:(NIUIContext *)context
                      andGridID:(NSInteger)gridID
{
  self = [super init];

  if (self) {
    _context = context;
    _gridID = gridID;
  }

  return self;
}

- (void)main
{
  [_context removeGridForID:_gridID];
}

@end
