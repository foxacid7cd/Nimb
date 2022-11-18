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

NS_ASSUME_NONNULL_BEGIN

@interface NimsUIGridRow : NSObject

- (instancetype)initWithFont:(NimsFont *)font gridSize:(GridSize)gridSize andIndex:(NSInteger)index;
- (void)setFont:(NimsFont *)font;
- (void)setGridSize:(GridSize)gridSize;
- (void)setIndex:(NSInteger)index;
- (void)applyChangedText:(NSString *)text startingAtX:(int64_t)x;
- (void)clearText;
- (CGRect)layerFrame;
- (NSAttributedString *)attributedString;

@end

NS_ASSUME_NONNULL_END
