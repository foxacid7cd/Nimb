//
//  NIUIWinFloatPosOpeeration.m
//  Nims
//
//  Created by Yevhenii Matviienko on 20.11.2022.
//  Copyright © 2022 foxacid7cd. All rights reserved.
//

#import "NIUIWinFloatPosOperation.h"

@implementation NIUIWinFloatPosOperation{
  NSNumber *_gridID;
  NSNumber *_windowRef;
  NIUIFloatAnchor _anchor;
  NSNumber *_anchorGridID;
  NIGridPoint _anchorPosition;
}

- (instancetype)initWithGridID:(NSNumber *)gridID
                     windowRef:(NSNumber *)windowRef
                        anchor:(NIUIFloatAnchor)anchor
                  anchorGridID:(NSNumber *)anchorGridID
                anchorPosition:(NIGridPoint)anchorPosition
{
  self = [super init];

  if (self != nil) {
    _gridID = gridID;
    _windowRef = windowRef;
    _anchor = anchor;
    _anchorGridID = anchorGridID;
    _anchorPosition = anchorPosition;
  }

  return self;
}

- (void)main
{
}

@end
