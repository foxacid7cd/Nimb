//
//  MainWindow.m
//  Nims
//
//  Created by Yevhenii Matviienko on 11.11.2022.
//  Copyright © 2022 foxacid7cd. All rights reserved.
//

#import "MainView.h"
#import "MainWindow.h"

@implementation MainWindow

- (instancetype)init {
  id mainView = [[MainView alloc] init];
  
  self = [super initWithContentRect:NSMakeRect(0, 0, 640, 480)
                          styleMask:NSWindowStyleMaskTitled | NSWindowStyleMaskClosable | NSWindowStyleMaskResizable backing:NSBackingStoreBuffered
                              defer:true];
  [self setContentView:mainView];
  
  return self;
};

@end
