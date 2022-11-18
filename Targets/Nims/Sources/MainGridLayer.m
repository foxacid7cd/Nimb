//
//  MainGridLayer.m
//  Nims
//
//  Created by Yevhenii Matviienko on 17.11.2022.
//  Copyright © 2022 foxacid7cd. All rights reserved.
//

#import "MainGridLayer.h"

@implementation MainGridLayer {
  NSArray<NSValue *> *_rowFrames;
  NSMutableArray<CATextLayer *> *_rowLayers;
}

- (instancetype)initWithRowFrames:(NSArray<NSValue *> *)rowFrames
{
  self = [super init];
  if (self != nil) {
    self->_rowFrames = rowFrames;
    self->_rowLayers = [@[] mutableCopy];
    [self updateRowLayerFrames];
  }
  return self;
}

- (void)setContentsScale:(CGFloat)contentsScale
{
  [super setContentsScale:contentsScale];
  
  for (CATextLayer *layer in self->_rowLayers) {
    [layer setContentsScale:contentsScale];
  }
}

- (void)setRowFrames:(NSArray<NSValue *> *)rowFrames
{
  self->_rowFrames = rowFrames;
  
  [self updateRowLayerFrames];
}

- (void)setRowAttributedString:(NSAttributedString *)rowAttributedString atY:(int64_t)y
{
  CATextLayer *rowLayer = [self->_rowLayers objectAtIndex:y];
  [rowLayer setString:rowAttributedString];
  [rowLayer setNeedsDisplay];
}

- (void)updateRowLayerFrames
{
  int64_t additionalRowLayersNeededCount = MAX(0, [self->_rowFrames count] - [self->_rowLayers count]);
  for (int64_t i = 0; i < additionalRowLayersNeededCount; i++) {
    CATextLayer *rowLayer = [[CATextLayer alloc] init];
    [rowLayer setContentsScale:[self contentsScale]];
    [self addSublayer:rowLayer];
    [self->_rowLayers addObject:rowLayer];
  }
  
  [self->_rowFrames enumerateObjectsUsingBlock:^(NSValue *value, NSUInteger index, BOOL *stop) {
    CATextLayer *rowLayer = [self->_rowLayers objectAtIndex:index];
    [rowLayer setFrame: [value rectValue]];
  }];
}

@end
