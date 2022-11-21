//
//  NIUIContext.m
//  Nims
//
//  Created by Yevhenii Matviienko on 19.11.2022.
//  Copyright © 2022 foxacid7cd. All rights reserved.
//

#import "NIUIContext.h"
#import "NSValue+Grid.h"

@implementation NIUIContext{
  CGFloat _windowZPositionCounter;
  CGFloat _floatingWindowZPositionCounter;

  NSMutableArray<id> *_grids;
}

- (instancetype)initWithAppearance:(NimsAppearance *)appearance
                     outerGridSize:(NIGridSize)outerGridSize
                         mainLayer:(CALayer *)mainLayer
{
  self = [super init];

  if (self != nil) {
    _appearance = appearance;
    _outerGridSize = outerGridSize;
    _mainLayer = mainLayer;

    _windowZPositionCounter = 10000;
    _floatingWindowZPositionCounter = 20000;

    _grids = [@[] mutableCopy];
  }

  return self;
}

- (CGFloat)nextWindowZPosition
{
  CGFloat value = _windowZPositionCounter;

  _windowZPositionCounter += 0.01;
  return value;
}

- (CGFloat)nextFloatingWindowZPosition
{
  CGFloat value = _floatingWindowZPositionCounter;

  _floatingWindowZPositionCounter += 0.01;
  return value;
}

- (NIUIGrid *)gridForID:(NSUInteger)gridID
{
  if (gridID >= [_grids count]) {
    return nil;
  }

  return _grids[gridID];
}

- (void)setGrid:(NIUIGrid *)grid forID:(NSUInteger)gridID
{
  NSInteger additionalArrayElementsNeededCount = MAX(0, gridID - [_grids count] + 1);

  for (NSInteger i = 0; i < additionalArrayElementsNeededCount; i++) {
    [_grids addObject:[NSNull null]];
  }

  _grids[gridID] = grid;
}

- (void)removeGridForID:(NSUInteger)gridID
{
  if (gridID >= [_grids count]) {
    return;
  }

  _grids[gridID] = [NSNull null];
}

@end
