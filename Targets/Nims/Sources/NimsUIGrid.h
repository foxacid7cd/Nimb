//
//  NimsUIGrid.h
//  Nims
//
//  Created by Yevhenii Matviienko on 12.11.2022.
//  Copyright © 2022 foxacid7cd. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "nvims.h"
#import "Grid.h"
#import "NimsFont.h"
#import "NimsUIGridRow.h"

NS_ASSUME_NONNULL_BEGIN

@interface NimsUIGrid : NSObject

- (instancetype)initWithFont:(NimsFont *)font frame:(GridRect)frame andOuterGridSize:(GridSize)outerGridSize;
- (void)setFont:(NimsFont *)font;
- (void)setFrame:(GridRect)frame andOuterGridSize:(GridSize)outerGridSize;
- (GridRect)frame;
- (CGRect)layerFrame;
- (NSArray<NimsUIGridRow *> *)rows;

@end

NS_ASSUME_NONNULL_END
