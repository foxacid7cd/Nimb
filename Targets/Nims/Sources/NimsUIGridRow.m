//
//  NimsUIGridRow.m
//  Nims
//
//  Created by Yevhenii Matviienko on 12.11.2022.
//  Copyright © 2022 foxacid7cd. All rights reserved.
//

#import <QuartzCore/QuartzCore.h>
#import "NimsUIGridRow.h"

@implementation NimsUIGridRow {
  int64_t _width;
  NSMutableAttributedString *_attributedString;
  CATextLayer *_layer;
}

- (instancetype)initWithFont:(NSFont *)font
{
  self->_font = font;
  self->_attributedString = [[NSMutableAttributedString alloc] initWithString:@""];
  self->_layer = [[CATextLayer alloc] init];
  [self->_layer setString:self->_attributedString];
  return [super init];
}

- (void)setWidth:(int64_t)width
{
  self->_width = width;
  
  int64_t additionalStringLength = MAX(0, width - [self->_attributedString length]);
  if (additionalStringLength > 0) {
    id additionalString = [@"" stringByPaddingToLength:additionalStringLength
                                            withString:@" "
                                       startingAtIndex:0];
    
    id attributes = @{
      NSFontAttributeName:self->_font,
      NSForegroundColorAttributeName: [NSColor whiteColor],
      NSBackgroundColorAttributeName: [NSColor blackColor]
    };
    id additionalAttributedString = [[NSAttributedString alloc] initWithString:additionalString
                                                                    attributes:attributes];
    
    [self->_attributedString beginEditing];
    [self->_attributedString appendAttributedString:additionalAttributedString];
    [self->_attributedString endEditing];
    [self->_layer setString:self->_attributedString];
  }
}

- (CALayer *)layer {
  return self->_layer;
}

@end
