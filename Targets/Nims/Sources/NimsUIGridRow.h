//
//  NimsUIGridRow.h
//  Nims
//
//  Created by Yevhenii Matviienko on 12.11.2022.
//  Copyright © 2022 foxacid7cd. All rights reserved.
//

#import <Cocoa/Cocoa.h>

NS_ASSUME_NONNULL_BEGIN

@interface NimsUIGridRow : NSObject

- (instancetype)initWithFont:(NSFont *)font;

@property (nonatomic, strong) NSFont *font;

- (void)setWidth:(int64_t)width;
- (CALayer *)layer;

@end

NS_ASSUME_NONNULL_END
