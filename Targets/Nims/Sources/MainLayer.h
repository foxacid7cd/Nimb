//
//  MainLayer.h
//  Nims
//
//  Created by Yevhenii Matviienko on 17.11.2022.
//  Copyright © 2022 foxacid7cd. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import <QuartzCore/QuartzCore.h>
#import "NimsFont.h"
#import "NimsUIHighlights.h"

NS_ASSUME_NONNULL_BEGIN

@interface MainLayer : CALayer

- (void)setFrame:(CGRect)frame rowFrames:(NSArray<NSValue *> *)rowFrames forGridWithID:(nonnull NSNumber *)gridID;
- (void)setZPosition:(CGFloat)zPosition forGridWithID:(NSNumber *)gridID;
- (void)setHidden:(BOOL)hidden forGridWithID:(NSNumber *)gridID;
- (void)setRowAttributedString:(NSAttributedString *)rowAttributedString atY:(int64_t)y forGridWithID:(NSNumber *)gridID;
- (void)destroyGridWithID:(NSNumber *)_id;
- (void)setCursorRect:(CGRect)cursorRect;

@end

NS_ASSUME_NONNULL_END
