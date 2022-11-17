//
//  AppDelegate.m
//  Nims
//
//  Created by Yevhenii Matviienko on 10.11.2022.
//  Copyright © 2022 foxacid7cd. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "NimsUI.h"

@interface AppDelegate : NSObject <NSApplicationDelegate> {
  NimsUI *_nimsUI;
}

@end

@implementation AppDelegate

- (void)applicationDidFinishLaunching:(NSNotification *)notification {
  id nimsUI = [[NimsUI alloc] init];
  [nimsUI start];
  self->_nimsUI = nimsUI;
}

@end
