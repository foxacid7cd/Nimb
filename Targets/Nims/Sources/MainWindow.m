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

- (BOOL)canBecomeKeyWindow
{
  return true;
}

- (void)keyDown:(NSEvent *)event
{
  NSString *characters = [event charactersIgnoringModifiers];
  
  NSString *specialKey;
  unichar character = [characters characterAtIndex:0];
  if ([event keyCode] == kVK_Escape) {
    specialKey = @"Esc";
    
  } else {
    switch (character) {
      case NSEnterCharacter:
        specialKey = @"CR";
        break;
        
      case NSDeleteCharacter:
        specialKey = @"BS";
        break;
        
      case NSBackspaceCharacter:
        specialKey = @"BS";
        break;
        
      case NSDeleteCharFunctionKey:
        specialKey = @"Del";
        break;
        
      case NSTabCharacter:
        specialKey = @"Tab";
        break;
        
      case NSCarriageReturnCharacter:
        specialKey = @"CR";
        break;
        
      case NSUpArrowFunctionKey:
        specialKey = @"Up";
        break;
        
      case NSDownArrowFunctionKey:
        specialKey = @"Down";
        break;
        
      case NSLeftArrowFunctionKey:
        specialKey = @"Left";
        break;
        
      case NSRightArrowFunctionKey:
        specialKey = @"Right";
        break;
        
      case NSInsertFunctionKey:
        specialKey = @"Insert";
        break;
        
      case NSHomeFunctionKey:
        specialKey = @"Home";
        break;
        
      case NSBeginFunctionKey:
        specialKey = @"Begin";
        break;
        
      case NSEndFunctionKey:
        specialKey = @"End";
        break;
        
      case NSPageUpFunctionKey:
        specialKey = @"PageUp";
        break;
        
      case NSPageDownFunctionKey:
        specialKey = @"PageDown";
        break;
        
      case NSHelpFunctionKey:
        specialKey = @"Help";
        break;
        
      case NSF1FunctionKey:
        specialKey = @"F1";
        break;
        
      case NSF2FunctionKey:
        specialKey = @"F2";
        break;
        
      case NSF3FunctionKey:
        specialKey = @"F3";
        break;
        
      case NSF4FunctionKey:
        specialKey = @"F4";
        break;
        
      case NSF5FunctionKey:
        specialKey = @"F5";
        break;
        
      case NSF6FunctionKey:
        specialKey = @"F6";
        break;
        
      case NSF7FunctionKey:
        specialKey = @"F7";
        break;
        
      case NSF8FunctionKey:
        specialKey = @"F8";
        break;
        
      case NSF9FunctionKey:
        specialKey = @"F9";
        break;
        
      case NSF10FunctionKey:
        specialKey = @"F10";
        break;
        
      case NSF11FunctionKey:
        specialKey = @"F11";
        break;
        
      case NSF12FunctionKey:
        specialKey = @"F12";
        break;
        
      case NSF13FunctionKey:
        specialKey = @"F13";
        break;
        
      case NSF14FunctionKey:
        specialKey = @"F14";
        break;
        
      case NSF15FunctionKey:
        specialKey = @"F15";
        break;
        
      case NSF16FunctionKey:
        specialKey = @"F16";
        break;
        
      case NSF17FunctionKey:
        specialKey = @"F17";
        break;
        
      case NSF18FunctionKey:
        specialKey = @"F18";
        break;
        
      case NSF19FunctionKey:
        specialKey = @"F19";
        break;
        
      case NSF20FunctionKey:
        specialKey = @"F20";
        break;
        
      case NSF21FunctionKey:
        specialKey = @"F21";
        break;
        
      case NSF22FunctionKey:
        specialKey = @"F22";
        break;
        
      case NSF23FunctionKey:
        specialKey = @"F23";
        break;
        
      case NSF24FunctionKey:
        specialKey = @"F24";
        break;
        
      case NSF25FunctionKey:
        specialKey = @"F25";
        break;
        
      case NSF26FunctionKey:
        specialKey = @"F26";
        break;
        
      case NSF27FunctionKey:
        specialKey = @"F27";
        break;
        
      case NSF28FunctionKey:
        specialKey = @"F28";
        break;
        
      case NSF29FunctionKey:
        specialKey = @"F29";
        break;
        
      case NSF30FunctionKey:
        specialKey = @"F30";
        break;
        
      case NSF31FunctionKey:
        specialKey = @"F31";
        break;
        
      case NSF32FunctionKey:
        specialKey = @"F32";
        break;
        
      case NSF33FunctionKey:
        specialKey = @"F33";
        break;
        
      case NSF34FunctionKey:
        specialKey = @"F34";
        break;
        
      case NSF35FunctionKey:
        specialKey = @"F35";
        break;
        
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
    keys = [NSString stringWithFormat:@"<%@-%@>", modifier, characters];
    
  } else if (specialKey != nil) {
    keys = [NSString stringWithFormat:@"<%@>", specialKey];
    
  } else {
    keys = [characters stringByReplacingOccurrencesOfString:@"<"
                                                 withString:@"<lt>"];
  }
  
  const char *cKeysData = [keys cStringUsingEncoding:NSUTF8StringEncoding];
  unsigned long length = strlen(cKeysData);
  nvim_string_t cKeys = { .data = (char *)cKeysData, .size = length };
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
}

@end
