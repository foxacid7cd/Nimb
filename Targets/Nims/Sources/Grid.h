//
//  Grid.h
//  Nims
//
//  Created by Yevhenii Matviienko on 12.11.2022.
//  Copyright © 2022 foxacid7cd. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

struct NIGridPoint {
  NSInteger x;
  NSInteger y;
};
typedef struct NIGridPoint NIGridPoint;

struct NIGridSize {
  NSInteger width;
  NSInteger height;
};
typedef struct NIGridSize NIGridSize;

struct NIGridRect {
  NIGridPoint origin;
  NIGridSize size;
};
typedef struct NIGridRect NIGridRect;

NS_INLINE NIGridPoint NIGridPointMake(NSInteger x, NSInteger y)
{
  NIGridPoint p;
  p.x = x;
  p.y = y;
  return p;
}

NS_INLINE _Bool NIGridPointEqualToGridPoint(NIGridPoint p1, NIGridPoint p2)
{
  return p1.x == p2.x && p1.y == p2.y;
}

NS_INLINE NIGridSize NIGridSizeMake(NSInteger width, NSInteger height)
{
  NIGridSize s;
  s.width = width;
  s.height = height;
  return s;
}

NS_INLINE _Bool NIGridSizeEqualToGridSize(NIGridSize s1, NIGridSize s2)
{
  return s1.width == s2.width && s1.height == s2.height;
}

NS_INLINE NIGridRect NIGridRectMake(NIGridPoint origin, NIGridSize size)
{
  NIGridRect r;
  r.origin = origin;
  r.size = size;
  return r;
}

NS_INLINE _Bool NIGridRectEqualToGridRect(NIGridRect r1, NIGridRect r2)
{
  return NIGridPointEqualToGridPoint(r1.origin, r2.origin) && NIGridSizeEqualToGridSize(r1.size, r2.size);
}

#define NIGridPointZero NIGridPointMake(0, 0)
#define NIGridSizeZero NIGridSizeMake(0, 0)
#define NIGridRectZero NIGridRectMake(NIGridPointMake(0, 0), NIGridSizeMake(0, 0));

NS_ASSUME_NONNULL_END
