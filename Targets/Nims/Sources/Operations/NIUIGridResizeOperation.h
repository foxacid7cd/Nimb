//
//  NIUIGridResizeOperation.h
//  Nims
//
//  Created by Yevhenii Matviienko on 19.11.2022.
//  Copyright © 2022 foxacid7cd. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "Grid.h"
#import "NIUIContext.h"

NS_ASSUME_NONNULL_BEGIN

@interface NIUIGridResizeOperation : NSOperation

- (instancetype)initWithContext:(NIUIContext *)context
                         gridID:(NSUInteger)gridID
                           size:(NIGridSize)size;

@end

NS_ASSUME_NONNULL_END