//
//  HighlightAttributes.h
//  Nims
//
//  Created by Yevhenii Matviienko on 18.11.2022.
//  Copyright © 2022 foxacid7cd. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "nvims.h"
#import "NimsFont.h"

NS_ASSUME_NONNULL_BEGIN

@interface HighlightAttributes : NSObject

- (void)applyAttrDefineWithRGBAttrs:(nvim_hl_attrs_t)rgb_attrs;
- (NSColor *)rgbForegroundColor;
- (NSColor *)rgbBackgroundColor;
- (NSColor *)rgbSpecialColor;

- (NSFont *)pickFont:(NimsFont *)font;

- (BOOL)isInversed;
- (BOOL)isBold;
- (BOOL)isItalic;

@end

NS_ASSUME_NONNULL_END
