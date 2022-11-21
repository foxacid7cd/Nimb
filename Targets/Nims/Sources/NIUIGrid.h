//
//  NIUIGrid.h
//  Nims
//
//  Created by Yevhenii Matviienko on 20.11.2022.
//  Copyright © 2022 foxacid7cd. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <Quartz/Quartz.h>
#import "Grid.h"
#import "nvims.h"
#import "NimsAppearance.h"

@interface NIUIGrid : NSObject

- (instancetype)initWithAppearance:(NimsAppearance *)appearance
                        superlayer:(CALayer *)superlayer;

@property (nonatomic) NIGridSize size;

- (void)setHidden:(BOOL)hidden;

- (void)applyRawLineAtGridY:(NSInteger)gridY
                 startGridX:(NSInteger)startGridX
                   endGridX:(NSInteger)endGridX
                 clearGridX:(NSInteger)clearGridX
             clearAttribute:(NSUInteger)clearAttribute
                      flags:(NSInteger)flags
                      chunk:(nvim_schar_t *)chunk
                 attributes:(nvim_sattr_t *)attributes;

- (void)applyWinPosWithWindowRef:(NSValue *)windowRef
                           frame:(NIGridRect)frame
                       zPosition:(CGFloat)zPosition;

- (void)applyGridClear;

@end
