//
//  NimsAppearance.h
//  Nims
//
//  Created by Yevhenii Matviienko on 18.11.2022.
//  Copyright © 2022 foxacid7cd. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "HighlightAttributes.h"

NS_ASSUME_NONNULL_BEGIN

@interface NimsAppearance : NSObject

- (instancetype)initWithFont:(NSFont *)font;

- (void)setFont:(NSFont *)font;
- (CGSize)cellSize;

- (void)applyDefaultColorsSetWithRGB_fg:(int32_t)rgb_fg
                                 rgb_bg:(int32_t)rgb_bg
                                 rgb_sp:(int32_t)rgb_sp;

- (void)applyAttrDefineForHighlightID:(NSUInteger)highlightID
                            rgb_attrs:(nvim_hl_attrs_t)rgb_attrs;

- (NSDictionary<NSAttributedStringKey, id> *)stringAttributesForHighlightID:(NSUInteger)highlightID;

- (NSFont *)fontForHighlightID:(NSUInteger)highlightID;

- (NSColor *)foregroundColorForHighlightID:(NSUInteger)highlightID;
- (NSColor *)backgroundColorForHighlightID:(NSUInteger)highlightID;
- (NSColor *)specialColorForHighlightID:(NSUInteger)highlightID;

@end

NS_ASSUME_NONNULL_END
