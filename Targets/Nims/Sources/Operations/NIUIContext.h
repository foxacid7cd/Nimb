//
//  NIUIContext.h
//  Nims
//
//  Created by Yevhenii Matviienko on 19.11.2022.
//  Copyright © 2022 foxacid7cd. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "NimsUIGrid.h"

NS_ASSUME_NONNULL_BEGIN

@interface NIUIContext : NSObject

- (instancetype)initWithAppearance:(NimsAppearance *)appearance
                     outerGridSize:(NSValue *)outerGridSize;

- (NimsAppearance *)appearance;
- (GridSize)outerGridSize;

- (CGFloat)nextGridZPosition;
- (CGFloat)nextWindowZPosition;
- (CGFloat)nextFloatingWindowZPosition;

- (void)markDirtyGridWithID:(NSNumber *)gridID;

- (NimsUIGrid * _Nullable)gridWithID:(NSNumber *)gridID;
- (void)setGrid:(NimsUIGrid *)grid forID:(NSNumber *)gridID;

@end

NS_ASSUME_NONNULL_END
