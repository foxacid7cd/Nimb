//
//  NIUIWinPosOperation.h
//  Nims
//
//  Created by Yevhenii Matviienko on 20.11.2022.
//  Copyright © 2022 foxacid7cd. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "nvims.h"

NS_ASSUME_NONNULL_BEGIN

@interface NIUIWinPosOperation : NSOperation

- (instancetype)initWithContext:(NIUIContext *)context
                         gridID:(NSUInteger)gridID
                      windowRef:(NSValue *)windowRef
                          frame:(NIGridRect)frame;

@end

NS_ASSUME_NONNULL_END
