//
//  MainLayer.m
//  Nims
//
//  Created by Yevhenii Matviienko on 17.11.2022.
//  Copyright © 2022 foxacid7cd. All rights reserved.
//

#import <CoreImage/CoreImage.h>
#import "MainGridLayer.h"
#import "MainLayer.h"

@implementation MainLayer {
  NSMutableDictionary<NSNumber *, MainGridLayer *> *_gridLayers;
  CALayer *_cursorLayer;
}

- (instancetype)init
{
  self = [super init];
  if (self != nil) {
    self->_gridLayers = [@{} mutableCopy];
    
    id cursorLayer = [[CALayer alloc] init];
    [cursorLayer setBackgroundColor:[[NSColor whiteColor] CGColor]];
    [cursorLayer setZPosition:3000];
    [cursorLayer setCompositingFilter:@"differenceBlendMode"];
    [self addSublayer:cursorLayer];
    self->_cursorLayer = cursorLayer;
  }
  return self;
}

- (void)setContentsScale:(CGFloat)contentsScale
{
  [super setContentsScale:contentsScale];
  
  for (MainGridLayer *gridLayer in [self->_gridLayers allValues]) {
    [gridLayer setContentsScale:contentsScale];
  }
  [self->_cursorLayer setContentsScale:contentsScale];
}

- (void)setFrame:(CGRect)frame rowFrames:(NSArray<NSValue *> *)rowFrames forGridWithID:(nonnull NSNumber *)gridID
{
  id gridLayer = [self->_gridLayers objectForKey:gridID];
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

- (void)setZPosition:(CGFloat)zPosition forGridWithID:(NSNumber *)gridID
{
  id gridLayer = [self->_gridLayers objectForKey:gridID];
  if (gridLayer != nil) {
    [gridLayer setZPosition:zPosition];
  }
}

- (void)setHidden:(BOOL)hidden forGridWithID:(NSNumber *)gridID
{
  id gridLayer = [self->_gridLayers objectForKey:gridID];
  if (gridLayer != nil) {
    [gridLayer setHidden:hidden];
  }
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

- (void)destroyGridWithID:(NSNumber *)_id
{
  id gridLayer = [self->_gridLayers objectForKey:_id];
  if (gridLayer != nil) {
    [gridLayer removeFromSuperlayer];
    [self->_gridLayers removeObjectForKey:_id];
  }
}

- (void)setCursorRect:(CGRect)cursorRect
{
  [self->_cursorLayer setFrame:cursorRect];
}

@end
