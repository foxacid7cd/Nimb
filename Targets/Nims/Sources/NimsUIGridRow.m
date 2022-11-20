//
//  NimsUIGridRow.m
//  Nims
//
//  Created by Yevhenii Matviienko on 12.11.2022.
//  Copyright © 2022 foxacid7cd. All rights reserved.
//

#import <QuartzCore/QuartzCore.h>
#import "NimsUIGridRow.h"
#import "NimsUIGridRowLayer.h"

@implementation NimsUIGridRow {
  NimsAppearance *_appearance;
  NIGridSize _gridSize;
  NSInteger _index;
  CGRect _layerFrame;
  CGFloat _contentsScale;
  NSMutableArray *_stringUpdates;
  
  NimsUIGridRowLayer *_layer;
}

- (instancetype)initWithAppearance:(NimsAppearance *)appearance
                          gridSize:(NIGridSize)gridSize
                          andIndex:(NSInteger)index
{
  self = [super init];
  if (self != nil) {
    self->_appearance = appearance;
    self->_gridSize = gridSize;
    self->_index = index;
    self->_stringUpdates = [@[] mutableCopy];
    
    [self updateLayerFrame];
  }
  return self;
}

- (void)setGridSize:(NIGridSize)gridSize
{
  self->_gridSize = gridSize;
  [self->_layer setGridWidth:gridSize.width];
  
  [self updateLayerFrame];
}

- (void)setIndex:(NSInteger)index
{
  self->_index = index;
  
  [self updateLayerFrame];
}

- (void)setString:(NSString *)string withHighlightID:(NSNumber *)highlightID atIndex:(NSUInteger)index;
{
  id update = [NSArray arrayWithObjects:@"setString", string, highlightID, [NSNumber numberWithUnsignedLong:index], nil];
  
  [self->_stringUpdates addObject:update];
}

- (void)clearText
{
  id update = [NSArray arrayWithObjects:@"clearText", nil];
  
  [self->_stringUpdates addObject:update];
}

- (void)highlightsUpdated
{
  [self->_layer highlightsUpdated];
  
  [self updateLayerFrame];
}

- (void)setContentsScale:(CGFloat)contentsScale
{
  self->_contentsScale = contentsScale;
}

- (void)flush
{
  id layer = self->_layer;
  if (layer == nil) {
    layer = [[NimsUIGridRowLayer alloc] initWithAppearance:self->_appearance
                                                 gridWidth:self->_gridSize.width];
    self->_layer = layer;
  }
  
  [layer setFrame:self->_layerFrame];
  [layer setContentsScale:self->_contentsScale];
  
  if ([self->_stringUpdates count] > 0) {
    for (id update in self->_stringUpdates) {
      NSString *typeString = [update objectAtIndex:0];
      
      if ([typeString isEqualToString:@"setString"]) {
        [layer setString:[update objectAtIndex:1]
         withHighlightID:[update objectAtIndex:2]
                 atIndex:[[update objectAtIndex:3] unsignedIntValue]];
        
      } else if ([typeString isEqualToString:@"clearText"]) {
        [layer clearText];
      }
    }
    
    [self->_stringUpdates removeAllObjects];
  }
}

- (CALayer *)layer
{
  return self->_layer;
}

- (void)updateLayerFrame
{
  CGSize cellSize = [self->_appearance cellSize];
  self->_layerFrame = CGRectMake(0,
                                 cellSize.height * (self->_gridSize.height - self->_index - 1),
                                 cellSize.width * self->_gridSize.width,
                                 cellSize.height);
}

@end
