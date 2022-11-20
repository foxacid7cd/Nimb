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

+ (NSNumber *)defaultHighlightID;

- (instancetype)initWithFont:(NSFont *)font;

- (void)setFont:(NSFont *)font;
- (CGSize)cellSize;

- (void)applyDefaultColorsSetWithRGB_fg:(int32_t)rgb_fg
                                 rgb_bg:(int32_t)rgb_bg
                                 rgb_sp:(int32_t)rgb_sp;

- (void)applyAttrDefineForHighlightID:(NSNumber *)highlightID
                            rgb_attrs:(nvim_hl_attrs_t)rgb_attrs;

- (NSDictionary<NSAttributedStringKey, id> *)stringAttributesForHighlightID:(NSNumber *)highlightID;

- (NSFont *)fontForHighlightID:(NSNumber *)highlightID;

- (NSColor *)foregroundColorForHighlightID:(NSNumber *)highlightID;
- (NSColor *)backgroundColorForHighlightID:(NSNumber *)highlightID;
- (NSColor *)specialColorForHighlightID:(NSNumber *)highlightID;

@end

NS_ASSUME_NONNULL_END
