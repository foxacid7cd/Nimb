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

@interface NIUIGrid : NSObject

- (instancetype)initWithSize:(NIGridSize)size;

@property (nonatomic) NIGridSize size;

- (void)applyRawLineAtGridY:(NSInteger)gridY
                 startGridX:(NSInteger)startGridX
                   endGridX:(NSInteger)endGridX
                 clearGridX:(NSInteger)clearGridX
             clearAttribute:(NSNumber *)clearAttribute
                      flags:(NSInteger)flags
                      chunk:(nvim_schar_t *)chunk
                 attributes:(nvim_sattr_t *)attributes;

@end
