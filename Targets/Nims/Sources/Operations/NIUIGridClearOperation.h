//
//  NIUIGridClearOperation.h
//  Nims
//
//  Created by Yevhenii Matviienko on 21.11.2022.
//  Copyright © 2022 foxacid7cd. All rights reserved.
//

@import Foundation;
#import "NIUIContext.h"

NS_ASSUME_NONNULL_BEGIN

@interface NIUIGridClearOperation : NSOperation

- (instancetype)initWithContext:(NIUIContext *)context
                      andGridID:(NSInteger)gridID;

@end

NS_ASSUME_NONNULL_END
