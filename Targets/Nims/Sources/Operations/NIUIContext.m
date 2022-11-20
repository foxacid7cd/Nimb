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
                              view:(NSView *)view
{
  self = [super init];

  if (self != nil) {
    _appearance = appearance;
    _outerGridSize = outerGridSize;
    _view = view;

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

- (NIUIGrid *)gridForID:(NSNumber *)gridID
{
  NSInteger index = [gridID integerValue];

  if (index >= [_grids count]) {
    return nil;
  }

  return [_grids objectAtIndex:index];
}

- (void)setGrid:(NIUIGrid *)grid forID:(NSNumber *)gridID
{
  NSInteger index = [gridID integerValue];

  NSInteger additionalArrayElementsNeededCount = MAX(0, index - [_grids count] + 1);

  for (NSInteger i = 0; i < additionalArrayElementsNeededCount; i++) {
    [_grids addObject:[NSNull null]];
  }

  [_grids setObject:grid atIndexedSubscript:index];
}

- (void)removeGridForID:(NSNumber *)gridID
{
  NSInteger index = [gridID integerValue];

  if (index >= [_grids count]) {
    return;
  }

  [_grids setObject:[NSNull null] atIndexedSubscript:index];
}

@end
