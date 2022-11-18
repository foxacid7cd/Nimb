//
//  MainLayer.h
//  Nims
//
//  Created by Yevhenii Matviienko on 17.11.2022.
//  Copyright © 2022 foxacid7cd. All rights reserved.
//

#import <QuartzCore/QuartzCore.h>
#import "NimsFont.h"

NS_ASSUME_NONNULL_BEGIN

@interface MainLayer : CALayer

- (void)setFrame:(CGRect)frame andRowFrames:(NSArray<NSValue *> *)rowFrames forGridWithID:(NSNumber *)gridID;
- (void)setRowAttributedString:(NSAttributedString *)rowAttributedString atY:(int64_t)y forGridWithID:(NSNumber *)gridID;

@end

NS_ASSUME_NONNULL_END
