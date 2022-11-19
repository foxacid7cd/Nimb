//
//  NSColor+NimsUI.h
//  Nims
//
//  Created by Yevhenii Matviienko on 18.11.2022.
//  Copyright © 2022 foxacid7cd. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "nvims.h"

NS_ASSUME_NONNULL_BEGIN

@interface NSColor (NimsUI)

+ (instancetype)colorFromRGBValue:(nvim_rgb_value_t)rgbValue alpha:(CGFloat)alpha;

@end

NS_ASSUME_NONNULL_END
