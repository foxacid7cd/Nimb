//
//  NIUIRawLineOperation.h
//  Nims
//
//  Created by Yevhenii Matviienko on 19.11.2022.
//  Copyright © 2022 foxacid7cd. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "NIUIContext.h"

@interface NIUIRawLineOperation : NSOperation

- (instancetype)initWithContext:(NIUIContext *)context
                         gridID:(NSNumber *)gridID
                          gridY:(NSInteger)gridY
                     startGridX:(NSInteger)startGridX
                       endGridX:(NSInteger)endGridX
                     clearGridX:(NSInteger)clearGridX
                 clearAttribute:(NSNumber *)clearAttribute
                          flags:(NSInteger)flags
                          chunk:(const nvim_schar_t *)chunk
                     attributes:(const nvim_sattr_t *)attributes;

@end
