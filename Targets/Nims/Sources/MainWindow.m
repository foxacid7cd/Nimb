//
//  MainWindow.m
//  Nims
//
//  Created by Yevhenii Matviienko on 18.11.2022.
//  Copyright © 2022 foxacid7cd. All rights reserved.
//

#import <Carbon/Carbon.h>
#import "nvims.h"
#import "Grid.h"
#import "MainGridLayer.h"
#import "MainWindow.h"

@implementation MainWindow {
  CGSize _cellSize;
}

- (void)setCellSize:(CGSize)cellSize
{
  self->_cellSize = cellSize;
}

- (BOOL)canBecomeMainWindow
{
  return true;
}

- (void)keyDown:(NSEvent *)event
{
  NSString *specialKey;
  unichar character = [[event characters] characterAtIndex:0];
  if ([event keyCode] == kVK_Escape) {
    specialKey = @"Esc";
    
  } else {
    switch (character) {
      case NSEnterCharacter:
        specialKey = @"CR";
        
      case NSDeleteCharacter:
        specialKey = @"BS";
        
      case NSBackspaceCharacter:
        specialKey = @"BS";
        
      case NSDeleteCharFunctionKey:
        specialKey = @"Del";
        
      case NSTabCharacter:
        specialKey = @"Tab";
        
      case NSCarriageReturnCharacter:
        specialKey = @"CR";
        
      case NSUpArrowFunctionKey:
        specialKey = @"Up";
        
      case NSDownArrowFunctionKey:
        specialKey = @"Down";
        
      case NSLeftArrowFunctionKey:
        specialKey = @"Left";
        
      case NSRightArrowFunctionKey:
        specialKey = @"Right";
        
      case NSInsertFunctionKey:
        specialKey = @"Insert";
        
      case NSHomeFunctionKey:
        specialKey = @"Home";
        
      case NSBeginFunctionKey:
        specialKey = @"Begin";
        
      case NSEndFunctionKey:
        specialKey = @"End";
        
      case NSPageUpFunctionKey:
        specialKey = @"PageUp";
        
      case NSPageDownFunctionKey:
        specialKey = @"PageDown";
        
      case NSHelpFunctionKey:
        specialKey = @"Help";
        
      case NSF1FunctionKey:
        specialKey = @"F1";
        
      case NSF2FunctionKey:
        specialKey = @"F2";
        
      case NSF3FunctionKey:
        specialKey = @"F3";
        
      case NSF4FunctionKey:
        specialKey = @"F4";
        
      case NSF5FunctionKey:
        specialKey = @"F5";
        
      case NSF6FunctionKey:
        specialKey = @"F6";
        
      case NSF7FunctionKey:
        specialKey = @"F7";
        
      case NSF8FunctionKey:
        specialKey = @"F8";
        
      case NSF9FunctionKey:
        specialKey = @"F9";
        
      case NSF10FunctionKey:
        specialKey = @"F10";
        
      case NSF11FunctionKey:
        specialKey = @"F11";
        
      case NSF12FunctionKey:
        specialKey = @"F12";
        
      case NSF13FunctionKey:
        specialKey = @"F13";
        
      case NSF14FunctionKey:
        specialKey = @"F14";
        
      case NSF15FunctionKey:
        specialKey = @"F15";
        
      case NSF16FunctionKey:
        specialKey = @"F16";
        
      case NSF17FunctionKey:
        specialKey = @"F17";
        
      case NSF18FunctionKey:
        specialKey = @"F18";
        
      case NSF19FunctionKey:
        specialKey = @"F19";
        
      case NSF20FunctionKey:
        specialKey = @"F20";
        
      case NSF21FunctionKey:
        specialKey = @"F21";
        
      case NSF22FunctionKey:
        specialKey = @"F22";
        
      case NSF23FunctionKey:
        specialKey = @"F23";
        
      case NSF24FunctionKey:
        specialKey = @"F24";
        
      case NSF25FunctionKey:
        specialKey = @"F25";
        
      case NSF26FunctionKey:
        specialKey = @"F26";
        
      case NSF27FunctionKey:
        specialKey = @"F27";
        
      case NSF28FunctionKey:
        specialKey = @"F28";
        
      case NSF29FunctionKey:
        specialKey = @"F29";
        
      case NSF30FunctionKey:
        specialKey = @"F30";
        
      case NSF31FunctionKey:
        specialKey = @"F31";
        
      case NSF32FunctionKey:
        specialKey = @"F32";
        
      case NSF33FunctionKey:
        specialKey = @"F33";
        
      case NSF34FunctionKey:
        specialKey = @"F34";
        
      case NSF35FunctionKey:
        specialKey = @"F35";
        
      default:
        specialKey = nil;
    }
  }
  
  NSString *modifier;
  NSEventModifierFlags modifierFlags = [event modifierFlags];
  if ((modifierFlags & NSEventModifierFlagShift) != 0) {
    modifier = @"S";
    
  } else if ((modifierFlags & NSEventModifierFlagControl) != 0) {
    modifier = @"C";
    
  } else if ((modifierFlags & NSEventModifierFlagOption) != 0) {
    modifier = @"M";
    
  } else if ((modifierFlags & NSEventModifierFlagCommand) != 0) {
    modifier = @"D";
    
  } else {
    modifier = nil;
  }
  
  NSString *keys;
  if (modifier != nil && specialKey != nil) {
    keys = [NSString stringWithFormat:@"<%@-%@>", modifier, specialKey];
    
  } else if (modifier != nil) {
    keys = [NSString stringWithFormat:@"<%@-%@>", modifier, [NSString stringWithCharacters:&character length:1]];
    
  } else if (specialKey != nil) {
    keys = [NSString stringWithFormat:@"<%@>", specialKey];
    
  } else {
    keys = [[event characters] stringByReplacingOccurrencesOfString:@"<"
                                                         withString:@"<lt>"];
  }
  
  nvim_string_t cKeys = { .data = (char *)[keys UTF8String], .size = [keys length] };
  nvims_input(cKeys);
}

- (void)mouseDown:(NSEvent *)event
{
  [self handleEvent:event];
}

- (void)mouseDragged:(NSEvent *)event
{
  [self handleEvent:event];
}

- (void)mouseUp:(NSEvent *)event
{
  [self handleEvent:event];
}

- (void)mouseMoved:(NSEvent *)event
{
  [self handleEvent:event];
}

- (void)rightMouseDown:(NSEvent *)event
{
  [self handleEvent:event];
}

- (void)rightMouseDragged:(NSEvent *)event
{
  [self handleEvent:event];
}

- (void)rightMouseUp:(NSEvent *)event
{
  [self handleEvent:event];
}

- (void)otherMouseDown:(NSEvent *)event
{
  [self handleEvent:event];
}

- (void)otherMouseDragged:(NSEvent *)event
{
  [self handleEvent:event];
}

- (void)otherMouseUp:(NSEvent *)event
{
  [self handleEvent:event];
}

- (void)scrollWheel:(NSEvent *)event
{
  [self handleEvent:event];
}

- (void)handleEvent:(NSEvent *)event
{
  CGSize cellSize = self->_cellSize;
  if (CGSizeEqualToSize(cellSize, CGSizeZero)) {
    return;
  }
  
  CGPoint locationInWindow = [event locationInWindow];
  
  NSView *contentView = [self contentView];
  if (contentView == nil) {
    return;
  }
  
  CALayer *layer = [[contentView layer] hitTest:locationInWindow];
  if (layer == nil) {
    return;
  }
  
  while (![layer isMemberOfClass:[MainGridLayer class]] && [layer superlayer] != nil) {
    layer = [layer superlayer];
  }
  
  CGPoint locationInGridLayer = [[contentView layer] convertPoint:locationInWindow
                                                          toLayer:layer];
  CGPoint upsideDownLocation = CGPointMake(locationInGridLayer.x,
                                           [layer bounds].size.height - locationInGridLayer.y);
  
  GridPoint point = GridPointMake(floor(upsideDownLocation.x / cellSize.width),
                                  floor(upsideDownLocation.y / cellSize.height));
  NSLog(@"%lli %lli", point.x, point.y);
}

@end
