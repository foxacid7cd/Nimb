//
//  NimsUIGridRow.h
//  Nims
//
//  Created by Yevhenii Matviienko on 12.11.2022.
//  Copyright © 2022 foxacid7cd. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import <QuartzCore/QuartzCore.h>
#import "NimsFont.h"
#import "Grid.h"
#import "NimsUIHighlights.h"

NS_ASSUME_NONNULL_BEGIN

@interface NimsUIGridRow : NSObject

- (instancetype)initWithHighlights:(NimsUIHighlights *)highlights
                              font:(NimsFont *)font
                          gridSize:(GridSize)gridSize
                          andIndex:(NSInteger)index;
- (void)setFont:(NimsFont *)font;
- (void)setGridSize:(GridSize)gridSize;
- (void)setIndex:(NSInteger)index;
- (void)setString:(NSString *)string withHighlightID:(NSNumber *)highlightID atIndex:(NSUInteger)index;
- (void)clearText;
- (void)highlightsUpdated;
- (void)setContentsScale:(CGFloat)contentsScale;
- (void)flush;
- (CALayer *)layer;

@end

NS_ASSUME_NONNULL_END