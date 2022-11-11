//
//  NvimUI.h
//  Nims
//
//  Created by Yevhenii Matviienko on 11.11.2022.
//  Copyright © 2022 foxacid7cd. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "NvimUIData.h"

NS_ASSUME_NONNULL_BEGIN

@interface NvimUI : NSObject

@property (nullable, nonatomic, copy) NvimUIData *data;

- (void) start;

- (void) grid:(int64_t)grid resizeWithWidth:(int64_t)width height:(int64_t)height;
- (void) grid:(int64_t)grid cursorGoToRow:(int64_t)row column:(int64_t)column;
- (void) grid:(int64_t)grid scrollWithTop:(int64_t)top left:(int64_t)left right:(int64_t)right rows:(int64_t)rows columns:(int64_t)columns;
- (void) grid:(int64_t)grid rawLineWithRow:(int64_t)row startColumn:(int64_t)startColumn endColumn:(int64_t)endColumn clearColumn:(int64_t)clearColumn clearAttribute:(int64_t) clearAttribute flags:(int64_t)flags chunk:(void *)chunk attributes:(void *)attributes;
- (void) clearGrid:(int64_t)grid;

@end

NS_ASSUME_NONNULL_END
