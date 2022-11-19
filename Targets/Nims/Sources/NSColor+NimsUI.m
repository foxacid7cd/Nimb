//
//  NSColor+NimsUI.m
//  Nims
//
//  Created by Yevhenii Matviienko on 18.11.2022.
//  Copyright © 2022 foxacid7cd. All rights reserved.
//

#import "NSColor+NimsUI.h"

@implementation NSColor (NimsUI)

+ (instancetype)colorFromRGBValue:(nvim_rgb_value_t)rgbValue alpha:(CGFloat)alpha
{
  return [NSColor colorWithRed:((rgbValue & 0xFF0000) >> 16) / 255.0
                         green:((rgbValue & 0xFF00) >> 8) / 255.0
                          blue:(rgbValue & 0xFF) / 255.0
                         alpha:alpha];
}

@end
