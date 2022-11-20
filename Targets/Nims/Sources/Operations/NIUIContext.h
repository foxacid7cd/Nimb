//
//  NIUIContext.h
//  Nims
//
//  Created by Yevhenii Matviienko on 19.11.2022.
//  Copyright © 2022 foxacid7cd. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "NimsAppearance.h"
#import "NIUIGrid.h"

NS_ASSUME_NONNULL_BEGIN

@interface NIUIContext : NSObject

- (instancetype)initWithAppearance:(NimsAppearance *)appearance
                     outerGridSize:(NIGridSize)outerGridSize;

@property (readonly) NimsAppearance *appearance;
@property (readonly) NIGridSize outerGridSize;

- (CGFloat)nextWindowZPosition;
- (CGFloat)nextFloatingWindowZPosition;

- (NIUIGrid * _Nullable)gridForID:(NSNumber *)gridID;
- (void)setGrid:(NIUIGrid *)grid forID:(NSNumber *)gridID;
- (void)removeGridForID:(NSNumber *)gridID;

@end

NS_ASSUME_NONNULL_END
