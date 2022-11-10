//
//  main.m
//  Nims
//
//  Created by Yevhenii Matviienko on 10.11.2022.
//  Copyright © 2022 foxacid7cd. All rights reserved.
//

#import <Cocoa/Cocoa.h>

extern int nvim_main(int argc, char **argv);

int main(int argc, char **argv)
{
  NSThread *nvimThread = [[NSThread alloc] initWithBlock:^{
    nvim_main(1, argv);
  }];
  [nvimThread start];
  
  return NSApplicationMain(argc, (const char**) argv);
}
