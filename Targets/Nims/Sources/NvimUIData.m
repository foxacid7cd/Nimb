//
//  NvimUIData.m
//  Nims
//
//  Created by Yevhenii Matviienko on 11.11.2022.
//  Copyright © 2022 foxacid7cd. All rights reserved.
//

#import "NvimUIData.h"

@implementation NvimUIData {
  void *bridge;
  void *loop;
}

- (instancetype)initWithBridge:(void *)bridge andLoop:(void *)loop {
  return [super init];
}

- (void *)loop {
  return self.loop;
}

@end
