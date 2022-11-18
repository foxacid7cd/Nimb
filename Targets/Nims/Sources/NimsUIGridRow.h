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
- (void)applyChangedText:(NSString *)text withHighlightID:(int64_t)highlightID startingAtX:(int64_t)x;
- (void)clearText;
- (void)highlightsUpdated;
- (CGRect)layerFrame;
- (NSAttributedString *)attributedString;

@end

NS_ASSUME_NONNULL_END
