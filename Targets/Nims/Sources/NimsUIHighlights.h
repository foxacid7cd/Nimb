//
//  NimsUIHighlights.h
//  Nims
//
//  Created by Yevhenii Matviienko on 18.11.2022.
//  Copyright © 2022 foxacid7cd. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "HighlightAttributes.h"

NS_ASSUME_NONNULL_BEGIN

@interface NimsUIHighlights : NSObject

- (void)applyDefaultColorsSetWithRGB_fg:(int32_t)rgb_fg
                                 rgb_bg:(int32_t)rgb_bg
                                 rgb_sp:(int32_t)rgb_sp;

- (void)applyAttrDefineForHighlightID:(NSNumber *)highlightID
                            rgb_attrs:(nvim_hl_attrs_t)rgb_attrs;

- (NSColor *)foregroundColorForHighlightID:(NSNumber *)highlightID;
- (NSColor *)backgroundColorForHighlightID:(NSNumber *)highlightID;
- (NSColor *)specialColorForHighlightID:(NSNumber *)highlightID;

- (NSFont *)pickFont:(NimsFont *)font forHighlightID:(NSNumber *)highlightID;

- (NSColor *)defaultRGBForegroundColor;
- (NSColor *)defaultRGBBackgroundColor;
- (NSColor *)defaultRGBSpecialColor;

@end

NS_ASSUME_NONNULL_END
