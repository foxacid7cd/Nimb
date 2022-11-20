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

- (instancetype)initWithGridID:(NSNumber *)gridID
                     windowRef:(NSNumber *)windowRef
                     gridFrame:(NIGridRect)gridFrame;

@end

NS_ASSUME_NONNULL_END
