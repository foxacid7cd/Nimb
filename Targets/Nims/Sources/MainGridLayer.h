//
//  MainGridLayer.h
//  Nims
//
//  Created by Yevhenii Matviienko on 17.11.2022.
//  Copyright © 2022 foxacid7cd. All rights reserved.
//

#import <QuartzCore/QuartzCore.h>
#import "NimsFont.h"

NS_ASSUME_NONNULL_BEGIN

@interface MainGridLayer : CALayer

- (instancetype)initWithRowFrames:(NSArray<NSValue *> *)rowFrames;
- (void)setRowFrames:(NSArray<NSValue *> *)rowFrames;
- (void)setRowAttributedString:(NSAttributedString *)rowAttributedString atY:(int64_t)y;

@end

NS_ASSUME_NONNULL_END
