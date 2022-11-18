//
//  AppDelegate.m
//  Nims
//
//  Created by Yevhenii Matviienko on 10.11.2022.
//  Copyright © 2022 foxacid7cd. All rights reserved.
//

#import "NimsUI.h"
#import "AppDelegate.h"

@implementation AppDelegate {
  NimsUI *_nimsUI;
}

- (void)applicationDidFinishLaunching:(NSNotification *)notification
{
  id nimsUI = [[NimsUI alloc] init];
  [nimsUI start];
  self->_nimsUI = nimsUI;
}

@end
