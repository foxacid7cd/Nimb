//
//  NIUIGridRow.h
//  Nims
//
//  Created by Yevhenii Matviienko on 21.11.2022.
//  Copyright © 2022 foxacid7cd. All rights reserved.
//

@import QuartzCore;
#import "Grid.h"
#import "NimsAppearance.h"

NS_ASSUME_NONNULL_BEGIN

@interface NIUIGridRow : NSObject <CALayerDelegate>

- (instancetype)initWithAppearance:(NimsAppearance *)appearance
                        superlayer:(CALayer *)superlayer;

- (void)setGridSize:(NIGridSize)gridSize andRowY:(NSInteger)y;

- (void)setWindowFrame:(NIGridRect)windowFrame;

- (void)setAttributedString:(NSAttributedString *)attributedString;

@end

NS_ASSUME_NONNULL_END
