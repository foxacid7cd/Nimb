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
  NSNumber *_gridID;
  NSNumber *_windowRef;
  NIGridRect _frame;
}

- (instancetype)initWithGridID:(NSNumber *)gridID
                     windowRef:(NSNumber *)windowRef
                         frame:(NIGridRect)frame
{
  self = [super init];

  if (self != nil) {
    _gridID = gridID;
    _windowRef = windowRef;
    _frame = frame;
  }

  return self;
}

- (void)main
{
}

@end
