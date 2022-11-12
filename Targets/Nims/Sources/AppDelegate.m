//
//  AppDelegate.m
//  Nims
//
//  Created by Yevhenii Matviienko on 10.11.2022.
//  Copyright © 2022 foxacid7cd. All rights reserved.
//


#import <Cocoa/Cocoa.h>
#import "MainWindow.h"
#import "NimsUI.h"

@interface AppDelegate : NSObject <NSApplicationDelegate>
{
  MainWindow *mainWindow;
  NimsUI *nimsUI;
}

@end

@implementation AppDelegate

- (instancetype)init {
  id mainWindow = [[MainWindow alloc] init];
  self->mainWindow = mainWindow;
  self->nimsUI = [[NimsUI alloc] initWithMainWindow:mainWindow];
  return [super init];
}

- (void)applicationDidFinishLaunching:(NSNotification *)notification {
  
  [self->nimsUI start];
  [self->mainWindow orderFront:NULL];
}

@end
