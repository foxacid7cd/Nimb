//
//  NIUIGridRow.m
//  Nims
//
//  Created by Yevhenii Matviienko on 21.11.2022.
//  Copyright © 2022 foxacid7cd. All rights reserved.
//

#import "NIUIGridRow.h"

@implementation NIUIGridRow {
  NimsAppearance *_appearance;
  CALayer *_superlayer;

  CALayer *_layer;

  NIGridSize _gridSize;
  NSInteger _y;
  NIGridRect _windowFrame;

  NSAttributedString *_attributedString;
}

- (instancetype)initWithAppearance:(NimsAppearance *)appearance
                        superlayer:(CALayer *)superlayer
{
  self = [super init];

  if (self) {
    _appearance = appearance;
    _superlayer = superlayer;

    _layer = [[CALayer alloc] init];
    [_layer setContentsScale:[[NSScreen mainScreen] backingScaleFactor]];
    [_layer setDelegate:self];

    [_superlayer addSublayer:_layer];
  }

  return self;
}

- (void)dealloc
{
  [_layer removeFromSuperlayer];
}

- (void)setGridSize:(NIGridSize)gridSize andRowY:(NSInteger)y
{
  _gridSize = gridSize;
  _y = y;

  [self updateLayerFrame];
}

- (void)setWindowFrame:(NIGridRect)windowFrame
{
  _windowFrame = windowFrame;

  [self updateLayerFrame];
}

- (void)setAttributedString:(NSAttributedString *)attributedString
{
  _attributedString = attributedString;

  [_layer setNeedsDisplayInRect:[_layer bounds]];
}

- (void)drawLayer:(CALayer *)layer inContext:(CGContextRef)context
{
  id graphicsContext = [NSGraphicsContext graphicsContextWithCGContext:context flipped:false];

  [NSGraphicsContext setCurrentContext:graphicsContext];
  [NSGraphicsContext saveGraphicsState];

  [_attributedString drawInRect:[layer bounds]];

  [NSGraphicsContext restoreGraphicsState];
}

- (void)updateLayerFrame
{
  NIGridRect gridFrame;

  if (_windowFrame.size.width == 0 && _windowFrame.size.height == 0) {
    gridFrame = NIGridRectMake(NIGridPointMake(0, _y), NIGridSizeMake(_gridSize.width, 1));
  } else {
    gridFrame = NIGridRectMake(NIGridPointMake(0, _y), NIGridSizeMake(_windowFrame.size.width, 1));
  }

  CGSize cellSize = [_appearance cellSize];

  CGRect frame = CGRectMake(gridFrame.origin.x * cellSize.width,
                            gridFrame.origin.y * cellSize.height,
                            gridFrame.size.width * cellSize.width,
                            gridFrame.size.height * cellSize.height);

  [_layer setFrame:frame];
}

@end
