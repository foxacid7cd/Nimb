//
//  MainView.m
//  Nims
//
//  Created by Yevhenii Matviienko on 11.11.2022.
//  Copyright © 2022 foxacid7cd. All rights reserved.
//

#import <Quartz/Quartz.h>
#import "MainView.h"

@implementation MainView {
  NSMutableAttributedString *attributedString;
}

- (instancetype)initWithFont: (NSFont *)font {
  self->attributedString = [[NSMutableAttributedString alloc] initWithString:@"hello world" attributes:@{
    NSFontAttributeName: font,
    NSForegroundColorAttributeName: [NSColor whiteColor],
    NSBackgroundColorAttributeName: [NSColor blackColor],
    NSLigatureAttributeName: @2,
  }];
  
  self = [super initWithFrame:NSZeroRect];
  [self setWantsLayer:true];
  
  [NSTimer scheduledTimerWithTimeInterval:0.5 repeats:true block:^(NSTimer * _Nonnull timer) {
    [self->attributedString beginEditing];
    
    [self->attributedString endEditing];
    
    [(CATextLayer *)[self layer] setString:self->attributedString];
  }];
  
  return self;
}

- (CALayer *)makeBackingLayer {
  id layer = [[CATextLayer alloc] init];
  [layer setContentsScale: [[NSScreen mainScreen] backingScaleFactor]];
  [layer setAllowsFontSubpixelQuantization:true];
  [layer setWrapped:true];
  
  NSFont *font = [NSFont monospacedSystemFontOfSize:13 weight:NSFontWeightRegular];
  
  id attributedString = [[NSMutableAttributedString alloc] initWithString:@"hello world" attributes:@{
    NSFontAttributeName: font,
    NSForegroundColorAttributeName: [NSColor whiteColor],
    NSBackgroundColorAttributeName: [NSColor blackColor],
    NSLigatureAttributeName: @2,
  }];
  [layer setString:attributedString];
  
  dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(1 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
    [attributedString addAttribute:NSForegroundColorAttributeName
                             value:[NSColor redColor]
                             range:NSMakeRange(2, 2)];
    [layer setString:attributedString];
  });
  
  return layer;
}

@end
