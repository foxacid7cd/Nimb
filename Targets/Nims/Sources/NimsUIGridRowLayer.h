//
//  NimsUIGridRowLayer.h
//  Nims
//
//  Created by Yevhenii Matviienko on 19.11.2022.
//  Copyright © 2022 foxacid7cd. All rights reserved.
//

#import <QuartzCore/QuartzCore.h>
#import "NimsUIHighlights.h"
#import "NimsFont.h"
#import "NimsUIGridRowTextStorage.h"

NS_ASSUME_NONNULL_BEGIN

@interface NimsUIGridRowLayer : CALayer

- (instancetype)initWithHighlights:(NimsUIHighlights *)highlights
                              font:(NimsFont *)font
                         gridWidth:(NSInteger)gridWidth;

- (void)setGridWidth:(NSInteger)gridWidth;
- (void)setString:(NSString *)string withHighlightID:(NSNumber *)highlightID atIndex:(NSUInteger)index;
- (void)clearText;
- (void)highlightsUpdated;

@end

NS_ASSUME_NONNULL_END