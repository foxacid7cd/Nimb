//
//  HighlightAttributes.h
//  Nims
//
//  Created by Yevhenii Matviienko on 18.11.2022.
//  Copyright © 2022 foxacid7cd. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "nvims.h"

NS_ASSUME_NONNULL_BEGIN

@interface HighlightAttributes : NSObject

- (instancetype)initWithFlags:(nvim_hl_attr_flags_t)flags
                 rgbForegound:(nvim_rgb_value_t)rgbForeground
                rgbBackground:(nvim_rgb_value_t)rgbBackground
                   rgbSpecial:(nvim_rgb_value_t)rgbSpecial
              ctermForeground:(int)ctermForeground
              ctermBackground:(int)ctermBackground
                        blend:(int)blend;
- (NSColor *)rgbForegroundColor;
- (NSColor *)rgbBackgroundColor;
- (NSColor *)rgbSpecialColor;
- (NSColor *)ctermForegroundColor;
- (NSColor *)ctermBackgroundColor;

@end

NS_ASSUME_NONNULL_END
