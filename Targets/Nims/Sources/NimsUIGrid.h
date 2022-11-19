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

typedef enum : int64_t {
  NimsUIGridAnchorTopLeft = 0,
  NimsUIGridAnchorTopRight,
  NimsUIGridAnchorBottomLeft,
  NimsUIGridAnchorBottomRight
} NimsUIGridAnchor;

NS_ASSUME_NONNULL_BEGIN

@interface NimsUIGrid : NSObject

- (instancetype)initWithHighlights:(NimsUIHighlights *)highlights
                              font:(NimsFont *)font
                            origin:(GridPoint)origin
                              size:(GridSize)size
                  andOuterGridSize:(GridSize)outerGridSize;
- (void)setFont:(NimsFont *)font;
- (void)setOrigin:(GridPoint)origin;
- (GridPoint)origin;
- (void)setSize:(GridSize)size;
- (GridSize)size;
- (void)setOuterGridSize:(GridSize)outerGridSize;
- (void)setNvimAnchor:(nvim_string_t)anchor;
- (void)setZPosition:(CGFloat)zPosition;
- (CGFloat)zPosition;
- (void)setHidden:(BOOL)hidden;
- (BOOL)isHidden;
- (void)highlightsUpdated;
- (void)clearText;
- (void)applyChangedText:(NSString *)text withHighlightID:(NSNumber *)highlightID startingAtX:(int64_t)x forY:(int64_t)y;
- (void)setContentsScale:(CGFloat)contentsScale;
- (void)scrollGrid:(GridRect)rect delta:(GridPoint)delta;
- (void)flush;
- (CALayer *)layer;
- (GridRect)frame;

@end

NS_ASSUME_NONNULL_END
