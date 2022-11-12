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

NS_INLINE GridPoint GridMakePoint(int64_t x, int64_t y) {
  GridPoint p;
  p.x = x;
  p.y = y;
  return p;
}


NS_INLINE GridSize GridMakeSize(int64_t width, int64_t height) {
  GridSize s;
  s.width = width;
  s.height = height;
  return s;
}

NS_INLINE GridRect GridMakeRect(GridPoint origin, GridSize size) {
  GridRect r;
  r.origin = origin;
  r.size = size;
  return r;
}

#define GridPointZero GridMakePoint(0, 0)
#define GridSizeZero GridMakeSize(0, 0)
#define GridRectZero GridMakeRect(GridMakePoint(0, 0), GridMakeSize(0, 0))

NS_ASSUME_NONNULL_END
