//
//  NSValue+Grid.m
//  Nims
//
//  Created by Yevhenii Matviienko on 19.11.2022.
//  Copyright © 2022 foxacid7cd. All rights reserved.
//

#import "NSValue+Grid.h"

@implementation NSValue (Grid)

+ (instancetype)valueWithGridPoint:(GridPoint)gridPoint
{
  return [NSValue valueWithBytes:&gridPoint
                        objCType:@encode(GridPoint)];
}

- (GridPoint)gridPointValue
{
  GridPoint gridPoint;
  [self getValue:&gridPoint];
  return gridPoint;
}

+ (instancetype)valueWithGridSize:(GridSize)gridSize
{
  return [NSValue valueWithBytes:&gridSize
                        objCType:@encode(GridSize)];
}

- (GridSize)gridSizeValue
{
  GridSize gridSize;
  [self getValue:&gridSize];
  return gridSize;
}

+ (instancetype)valueWithGridRect:(GridRect)gridRect
{
  return [NSValue valueWithBytes:&gridRect
                        objCType:@encode(GridRect)];
}

- (GridRect)gridRectValue
{
  GridRect gridRect;
  [self getValue:&gridRect];
  return gridRect;
}

@end
