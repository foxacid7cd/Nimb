//
//  AppDelegate.m
//  Nims
//
//  Created by Yevhenii Matviienko on 10.11.2022.
//  Copyright © 2022 foxacid7cd. All rights reserved.
//

#import "AppDelegate.h"
#import "NimsUI.h"

@implementation AppDelegate {
  NimsUI *_nimsUI;
}

- (void)applicationDidFinishLaunching:(NSNotification *)notification
{
  _nimsUI = [[NimsUI alloc] init];
  [_nimsUI start];
}

@end
