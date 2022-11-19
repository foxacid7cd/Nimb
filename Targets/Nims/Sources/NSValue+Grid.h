//
//  NSValue+Grid.h
//  Nims
//
//  Created by Yevhenii Matviienko on 19.11.2022.
//  Copyright © 2022 foxacid7cd. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "Grid.h"

NS_ASSUME_NONNULL_BEGIN

@interface NSValue (Grid)

+ (instancetype)valueWithGridPoint:(GridPoint)gridPoint;
- (GridPoint)gridPointValue;

+ (instancetype)valueWithGridSize:(GridSize)gridSize;
- (GridSize)gridSizeValue;

+ (instancetype)valueWithGridRect:(GridRect)gridRect;
- (GridRect)gridRectValue;

@end

NS_ASSUME_NONNULL_END
