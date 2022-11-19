//
//  NimsUIGridRowLayer.m
//  Nims
//
//  Created by Yevhenii Matviienko on 19.11.2022.
//  Copyright © 2022 foxacid7cd. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "NimsUIGridRowLayer.h"

@implementation NimsUIGridRowLayer {
  NimsAppearance *_appearance;
  NSInteger _gridWidth;
  NimsUIGridRowTextStorage *_textStorage;
  NSLayoutManager *_layoutManager;
  NSTextContainer *_textContainer;
}

- (instancetype)initWithAppearance:(NimsAppearance *)appearance
                         gridWidth:(NSInteger)gridWidth
{
  self = [super init];
  if (self != nil) {
    self->_appearance = appearance;
    
    [self setGridWidth:gridWidth];
    
    id textStorage = [[NimsUIGridRowTextStorage alloc] initWithAppearance:appearance
                                                                gridWidth:gridWidth];
    id layoutManager = [[NSLayoutManager alloc] init];
    [layoutManager setUsesFontLeading:false];
    
    id textContainer = [[NSTextContainer alloc] init];
    
    [textContainer setMaximumNumberOfLines:1];
    [textContainer setLineBreakMode:NSLineBreakByClipping];
    [textContainer setLineFragmentPadding:0];
    [layoutManager addTextContainer:textContainer];
    [textStorage addLayoutManager:layoutManager];
    
    self->_textStorage = textStorage;
    self->_layoutManager = layoutManager;
    self->_textContainer = textContainer;
    
    [self setNeedsDisplayOnBoundsChange:true];
    [self setGeometryFlipped:true];
  }
  return self;
}

- (void)setGridWidth:(NSInteger)gridWidth
{
  [self->_textStorage setGridWidth:gridWidth];
  
  CGSize cellSize = [self->_appearance cellSize];
  [self->_textContainer setSize:NSMakeSize(gridWidth * cellSize.width,
                                           cellSize.height)];
}

- (void)setString:(NSString *)string withHighlightID:(NSNumber *)highlightID atIndex:(NSUInteger)index
{
  [self->_textStorage setString:string withHighlightID:highlightID atIndex:index];
}

- (void)clearText
{
  [self->_textStorage clearText];
}

- (void)highlightsUpdated
{
  [self->_textStorage highlightsUpdated];
}

- (void)drawInContext:(CGContextRef)context
{
  id graphicsContext = [NSGraphicsContext graphicsContextWithCGContext:context flipped:true];
  [NSGraphicsContext setCurrentContext:graphicsContext];
  
  [NSGraphicsContext saveGraphicsState];
  
  NSRange glyphRange = [self->_layoutManager glyphRangeForTextContainer:self->_textContainer];
  
  [self->_layoutManager drawBackgroundForGlyphRange:glyphRange atPoint:NSZeroPoint];
  [self->_layoutManager drawGlyphsForGlyphRange:glyphRange atPoint:NSZeroPoint];
  
  [NSGraphicsContext restoreGraphicsState];
}

@end
