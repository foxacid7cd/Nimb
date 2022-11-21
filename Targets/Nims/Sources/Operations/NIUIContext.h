//
//  NIUIContext.h
//  Nims
//
//  Created by Yevhenii Matviienko on 19.11.2022.
//  Copyright © 2022 foxacid7cd. All rights reserved.
//

@import Foundation;
#import "NimsAppearance.h"
#import "NIUIGrid.h"

NS_ASSUME_NONNULL_BEGIN

@interface NIUIContext : NSObject

- (instancetype)initWithAppearance:(NimsAppearance *)appearance
                     outerGridSize:(NIGridSize)outerGridSize
                         mainLayer:(CALayer *)mainLayer;

@property (readonly) NimsAppearance *appearance;
@property (readonly) NIGridSize outerGridSize;
@property (readonly) CALayer *mainLayer;

- (CGFloat)nextWindowZPosition;
- (CGFloat)nextFloatingWindowZPosition;

- (NIUIGrid *_Nullable)gridForID:(NSUInteger)gridID;
- (void)setGrid:(NIUIGrid *)grid forID:(NSUInteger)gridID;
- (void)removeGridForID:(NSUInteger)gridID;

@end

NS_ASSUME_NONNULL_END
