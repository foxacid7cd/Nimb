//
//  Grid.h
//  Nims
//
//  Created by Yevhenii Matviienko on 12.11.2022.
//  Copyright © 2022 foxacid7cd. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

struct GridPoint {
  int64_t x;
  int64_t y;
};
typedef struct GridPoint GridPoint;

struct GridSize {
  int64_t width;
  int64_t height;
};
typedef struct GridSize GridSize;

struct GridRect {
  GridPoint origin;
  GridSize size;
};
typedef struct GridRect GridRect;

NS_INLINE GridPoint GridPointMake(int64_t x, int64_t y)
{
  GridPoint p;
  p.x = x;
  p.y = y;
  return p;
}

NS_INLINE _Bool GridPointEqualToGridPoint(GridPoint p1, GridPoint p2)
{
  return p1.x == p2.x && p1.y == p2.y;
}

NS_INLINE GridSize GridSizeMake(int64_t width, int64_t height)
{
  GridSize s;
  s.width = width;
  s.height = height;
  return s;
}

NS_INLINE _Bool GridSizeEqualToGridSize(GridSize s1, GridSize s2)
{
  return s1.width == s2.width && s1.height == s2.height;
}

NS_INLINE GridRect GridRectMake(GridPoint origin, GridSize size)
{
  GridRect r;
  r.origin = origin;
  r.size = size;
  return r;
}

NS_INLINE _Bool GridRectEqualToGridRect(GridRect r1, GridRect r2)
{
  return GridPointEqualToGridPoint(r1.origin, r2.origin) && GridSizeEqualToGridSize(r1.size, r2.size);
}

#define GridPointZero GridPointMake(0, 0)
#define GridSizeZero GridSizeMake(0, 0)
#define GridRectZero GridRectMake(GridPointMake(0, 0), GridSizeMake(0, 0))

NS_ASSUME_NONNULL_END
