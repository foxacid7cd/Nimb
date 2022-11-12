//
//  NimsUIGrid.h
//  Nims
//
//  Created by Yevhenii Matviienko on 12.11.2022.
//  Copyright © 2022 foxacid7cd. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "Grid.h"

NS_ASSUME_NONNULL_BEGIN

@interface NimsUIGrid : NSObject

- (instancetype)initWithID:(NSNumber *)_id;

- (NSNumber *)_id;

- (void)setSize:(GridSize)size;

@end

NS_ASSUME_NONNULL_END
