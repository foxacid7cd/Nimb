//
//  NSValue+Grid.m
//  Nims
//
//  Created by Yevhenii Matviienko on 19.11.2022.
//  Copyright © 2022 foxacid7cd. All rights reserved.
//

#import "NSValue+Grid.h"

@implementation NSValue (Grid)

+ (instancetype)valueWithGridPoint:(NIGridPoint)gridPoint
{
  return [NSValue valueWithBytes:&gridPoint
                        objCType:@encode(NIGridPoint)];
}

- (NIGridPoint)gridPointValue
{
  NIGridPoint gridPoint;
  [self getValue:&gridPoint];
  return gridPoint;
}

+ (instancetype)valueWithGridSize:(NIGridSize)gridSize
{
  return [NSValue valueWithBytes:&gridSize
                        objCType:@encode(NIGridSize)];
}

- (NIGridSize)gridSizeValue
{
  NIGridSize gridSize;
  [self getValue:&gridSize];
  return gridSize;
}

+ (instancetype)valueWithGridRect:(NIGridRect)gridRect
{
  return [NSValue valueWithBytes:&gridRect
                        objCType:@encode(NIGridRect)];
}

- (NIGridRect)gridRectValue
{
  NIGridRect gridRect;
  [self getValue:&gridRect];
  return gridRect;
}

@end
