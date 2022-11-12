//
//  AppDelegate.m
//  Nims
//
//  Created by Yevhenii Matviienko on 10.11.2022.
//  Copyright © 2022 foxacid7cd. All rights reserved.
//


#import <Cocoa/Cocoa.h>
#import "MainWindow.h"


@interface AppDelegate : NSObject <NSApplicationDelegate> {
  MainWindow *mainWindow;
}

@end

@implementation AppDelegate

- (instancetype)init {
  self->mainWindow = [[MainWindow alloc] init];
  return [super init];
}

- (void)applicationDidFinishLaunching:(NSNotification *)notification {
  [self->mainWindow orderFront:NULL];
}

@end
