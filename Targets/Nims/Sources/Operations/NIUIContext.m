//
//  NIUIContext.m
//  Nims
//
//  Created by Yevhenii Matviienko on 19.11.2022.
//  Copyright © 2022 foxacid7cd. All rights reserved.
//

#import "NSValue+Grid.h"
#import "NIUIContext.h"

@implementation NIUIContext {
  NimsAppearance *_appearance;
  GridSize _outerGridSize;
  
  CGFloat _gridZPositionCounter;
  CGFloat _windowZPositionCounter;
  CGFloat _floatingWindowZPositionCounter;
  
  NSMutableSet *_changedGridIDs;
  NSMutableDictionary<NSNumber *, NimsUIGrid *> *_grids;
}

- (instancetype)initWithAppearance:(NimsAppearance *)appearance
                     outerGridSize:(nonnull NSValue *)outerGridSize
{
  self = [super init];
  if (self != nil) {
    _appearance = appearance;
    _outerGridSize = [outerGridSize gridSizeValue];
    
    _gridZPositionCounter = 0;
    _windowZPositionCounter = 1000;
    _floatingWindowZPositionCounter = 2000;
    
    _changedGridIDs = [[NSSet set] mutableCopy];
    _grids = [@[] mutableCopy];
  }
  return self;
}

- (NimsAppearance *)appearance
{
  return _appearance;
}

- (GridSize)outerGridSize
{
  return _outerGridSize;
}

- (CGFloat)nextGridZPosition
{
  CGFloat value = _gridZPositionCounter;
  _gridZPositionCounter += 0.01;
  return value;
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

- (void)markDirtyGridWithID:(NSNumber *)gridID
{
  [_changedGridIDs addObject:gridID];
}

- (NimsUIGrid *)gridWithID:(NSNumber *)gridID
{
  return [_grids objectForKey:gridID];
}

- (void)setGrid:(NimsUIGrid *)grid forID:(NSNumber *)gridID
{
  [_grids setObject:grid forKey:gridID];
}

@end
