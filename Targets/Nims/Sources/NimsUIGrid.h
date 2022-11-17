//
//  NimsUIGrid.h
//  Nims
//
//  Created by Yevhenii Matviienko on 12.11.2022.
//  Copyright © 2022 foxacid7cd. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "Grid.h"

NS_ASSUME_NONNULL_BEGIN

@interface NimsUIGrid : NSObject

- (instancetype)initWithID:(NSNumber *)_id andFont:(NSFont *)font;

- (NSNumber *)_id;

- (void)setSize:(GridSize)size;

@end

NS_ASSUME_NONNULL_END
