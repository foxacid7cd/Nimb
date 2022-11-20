//
//  NIUIFloatAnchor.h
//  Nims
//
//  Created by Yevhenii Matviienko on 20.11.2022.
//  Copyright © 2022 foxacid7cd. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "nvims.h"

#ifndef NIUIFloatAnchor_h
#define NIUIFloatAnchor_h

typedef enum : NSInteger {
  NIUIFloatAnchorTopLeft = 0,
  NIUIFloatAnchorTopRight,
  NIUIFloatAnchorBottomLeft,
  NIUIFloatAnchorBottomRight
} NIUIFloatAnchor;

NIUIFloatAnchor NIUIFloatAnchorMakeFromNvimArgument(nvim_string_t nvimArgument);

#endif /* NIUIFloatAnchor_h */
