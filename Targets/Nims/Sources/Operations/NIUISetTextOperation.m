//
//  NIUISetTextOperation.m
//  Nims
//
//  Created by Yevhenii Matviienko on 19.11.2022.
//  Copyright © 2022 foxacid7cd. All rights reserved.
//

#import "NIUISetTextOperation.h"

@implementation NIUISetTextOperation {
  NIUIContext *_context;
  NSNumber *_gridID;
  NSString *_text;
  NSNumber *_highlightID;
  GridPoint _gridPoint;
}

- (instancetype)initWithContext:(NIUIContext *)context
                         gridID:(NSNumber *)gridID
                           text:(NSString *)text
                    highlightID:(NSNumber *)highlightID
                      gridPoint:(GridPoint)gridPoint;
{
  self = [super init];
  if (self != nil) {
    _context = context;
    _gridID = gridID;
    _text = text;
    _highlightID = highlightID;
    _gridPoint = gridPoint;
  }
  return self;
}

- (void)main
{
  NimsUIGrid *grid = [_context gridWithID:_gridID];
  if (grid == nil) {
    return;
  }
  
  [grid setString:_text
  withHighlightID:_highlightID
          atIndex:_gridPoint.x
        forRowAtY:_gridPoint.y];
}

@end
