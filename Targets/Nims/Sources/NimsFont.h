//
//  NimsFont.h
//  Nims
//
//  Created by Yevhenii Matviienko on 17.11.2022.
//  Copyright © 2022 foxacid7cd. All rights reserved.
//

#import <Cocoa/Cocoa.h>

NS_ASSUME_NONNULL_BEGIN

@interface NimsFont : NSObject

- (instancetype)initWithFont:(NSFont *)font;
- (NSFont *)font;
- (CGSize)cellSize;
- (NSParagraphStyle *)paragraphStyle;

@end

NS_ASSUME_NONNULL_END
