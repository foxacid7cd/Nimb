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

+ (instancetype)valueWithGridPoint:(NIGridPoint)gridPoint;
@property (readonly) NIGridPoint gridPointValue;

+ (instancetype)valueWithGridSize:(NIGridSize)gridSize;
@property (readonly) NIGridSize gridSizeValue;

+ (instancetype)valueWithGridRect:(NIGridRect)gridRect;
@property (readonly) NIGridRect gridRectValue;

@end

NS_ASSUME_NONNULL_END
