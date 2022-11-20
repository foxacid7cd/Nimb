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
#import "NimsUIGridRow.h"
#import "NimsAppearance.h"

typedef enum : int64_t {
  NimsUIGridAnchorTopLeft = 0,
  NimsUIGridAnchorTopRight,
  NimsUIGridAnchorBottomLeft,
  NimsUIGridAnchorBottomRight
} NimsUIGridAnchor;

NS_ASSUME_NONNULL_BEGIN

@interface NimsUIGrid : NSObject

- (instancetype)initWithAppearance:(NimsAppearance *)appearance
                            origin:(NIGridPoint)origin
                              size:(NIGridSize)size
                     outerGridSize:(NIGridSize)outerGridSize
                         zPosition:(CGFloat)zPosition;
- (void)setOrigin:(NIGridPoint)origin;
- (NIGridPoint)origin;
- (void)setSize:(NIGridSize)size;
- (NIGridSize)size;
- (void)setOuterGridSize:(NIGridSize)outerGridSize;
- (void)setNvimAnchor:(nvim_string_t)anchor;
- (void)setZPosition:(CGFloat)zPosition;
- (CGFloat)zPosition;
- (void)setHidden:(BOOL)hidden;
- (BOOL)isHidden;
- (void)highlightsUpdated;
- (void)clearText;
- (void)setString:(NSString *)string withHighlightID:(NSNumber *)highlightID atIndex:(NSInteger)index forRowAtY:(NSInteger)y;
- (void)setContentsScale:(CGFloat)contentsScale;
- (void)scrollGrid:(NIGridRect)rect delta:(NIGridPoint)delta;
- (void)flush;
- (CALayer *)layer;

@end

NS_ASSUME_NONNULL_END
