//
//  MainLayer.m
//  Nims
//
//  Created by Yevhenii Matviienko on 17.11.2022.
//  Copyright © 2022 foxacid7cd. All rights reserved.
//

#import "MainGridLayer.h"
#import "MainLayer.h"

@implementation MainLayer {
  NSMutableDictionary<NSNumber *, MainGridLayer *> *_gridLayers;
}

- (instancetype)init
{
  self = [super init];
  if (self != nil) {
    self->_gridLayers = [@{} mutableCopy];
  }
  return self;
}

- (void)setContentsScale:(CGFloat)contentsScale
{
  [super setContentsScale:contentsScale];
  
  for (MainGridLayer *gridLayer in [self->_gridLayers allValues]) {
    [gridLayer setContentsScale:contentsScale];
  }
}

- (void)setFrame:(CGRect)frame andRowFrames:(nonnull NSArray<NSValue *> *)rowFrames forGridWithID:(NSNumber *)gridID
{
  MainGridLayer *gridLayer = [self->_gridLayers objectForKey:gridID];
  if (gridLayer == nil) {
    gridLayer = [[MainGridLayer alloc] initWithRowFrames:rowFrames];
    [gridLayer setContentsScale:[self contentsScale]];
    [self addSublayer:gridLayer];
    [self->_gridLayers setObject:gridLayer forKey:gridID];
    
  } else {
    [gridLayer setRowFrames:rowFrames];
  }
  
  [gridLayer setFrame:frame];
}

- (void)setRowAttributedString:(NSAttributedString *)rowAttributedString atY:(int64_t)y forGridWithID:(NSNumber *)gridID
{
  MainGridLayer *gridLayer = [self->_gridLayers objectForKey:gridID];
  if (gridLayer == nil) {
    NSLog(@"setRowAttributedString in MainLayer called for unexisting grid with id: %@", gridID);
    return;
  }
  
  [gridLayer setRowAttributedString:rowAttributedString atY:y];
}

@end
