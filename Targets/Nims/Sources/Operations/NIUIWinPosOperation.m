//
//  NIUIWinPosOperation.m
//  Nims
//
//  Created by Yevhenii Matviienko on 20.11.2022.
//  Copyright © 2022 foxacid7cd. All rights reserved.
//

#import "NIUIGridResizeOperation.h"
#import "NIUIWinPosOperation.h"

@implementation NIUIWinPosOperation {
  NIUIContext *_context;
  NSUInteger _gridID;
  NSValue *_windowRef;
  NIGridRect _frame;
}

- (instancetype)initWithContext:(NIUIContext *)context
                         gridID:(NSUInteger)gridID
                      windowRef:(NSValue *)windowRef
                          frame:(NIGridRect)frame
{
  self = [super init];

  if (self != nil) {
    _context = context;
    _gridID = gridID;
    _windowRef = windowRef;
    _frame = frame;
  }

  return self;
}

- (void)main
{
  NIUIGrid *grid = [_context gridForID:_gridID];

  [grid applyWinPosWithWindowRef:_windowRef
                           frame:_frame
                       zPosition:[_context nextWindowZPosition]];
  
  [grid setHidden:false];
}

@end
