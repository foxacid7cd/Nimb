//
//  NimsUIGridRowTextStorage.h
//  Nims
//
//  Created by Yevhenii Matviienko on 19.11.2022.
//  Copyright © 2022 foxacid7cd. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "NimsUIHighlights.h"

NS_ASSUME_NONNULL_BEGIN

@interface NimsUIGridRowTextStorage : NSTextStorage

- (instancetype)initWithHighlights:(NimsUIHighlights *)highlights font:(NimsFont *)font gridWidth:(NSInteger)gridWidth;
- (void)setGridWidth:(NSInteger)gridWidth;
- (void)setString:(NSString *)string withHighlightID:(NSNumber *)highlightID atIndex:(NSUInteger)index;
- (void)clearText;
- (void)highlightsUpdated;

@end

NS_ASSUME_NONNULL_END
