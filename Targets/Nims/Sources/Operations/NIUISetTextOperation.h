//
//  NIUISetTextOperation.h
//  Nims
//
//  Created by Yevhenii Matviienko on 19.11.2022.
//  Copyright © 2022 foxacid7cd. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "NIUIContext.h"

NS_ASSUME_NONNULL_BEGIN

@interface NIUISetTextOperation : NSOperation

- (instancetype)initWithContext:(NIUIContext *)context
                         gridID:(NSNumber *)gridID
                           text:(NSString *)text
                    highlightID:(NSNumber *)highlightID
                      gridPoint:(GridPoint)gridPoint;

@end

NS_ASSUME_NONNULL_END
