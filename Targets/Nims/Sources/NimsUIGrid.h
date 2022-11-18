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
#import "NimsUIHighlights.h"

NS_ASSUME_NONNULL_BEGIN

@interface NimsUIGrid : NSObject

- (instancetype)initWithHighlights:(NimsUIHighlights *)highlights
                              font:(NimsFont *)font
                             frame:(GridRect)frame
                  andOuterGridSize:(GridSize)outerGridSize;
- (void)setFont:(NimsFont *)font;
- (void)setFrame:(GridRect)frame andOuterGridSize:(GridSize)outerGridSize;
- (void)highlightsUpdated;
- (GridRect)frame;
- (CGRect)layerFrame;
- (NSColor *)backgroundColor;
- (NSArray<NimsUIGridRow *> *)rows;

@end

NS_ASSUME_NONNULL_END
