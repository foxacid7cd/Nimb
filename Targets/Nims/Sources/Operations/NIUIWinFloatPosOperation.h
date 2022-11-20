//
//  NIUIWinFloatPosOpeeration.h
//  Nims
//
//  Created by Yevhenii Matviienko on 20.11.2022.
//  Copyright © 2022 foxacid7cd. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "NIUIFloatAnchor.h"
#import "Grid.h"

NS_ASSUME_NONNULL_BEGIN

@interface NIUIWinFloatPosOperation : NSOperation

- (instancetype)initWithGridID:(NSNumber *)gridID
                     windowRef:(NSNumber *)windowRef
                        anchor:(NIUIFloatAnchor)anchor
                  anchorGridID:(NSNumber *)anchorGridID
                anchorPosition:(NIGridPoint)anchorPosition;

@end

NS_ASSUME_NONNULL_END
