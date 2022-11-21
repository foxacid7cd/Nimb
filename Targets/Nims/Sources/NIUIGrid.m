//
//  NIUIGrid.m
//  Nims
//
//  Created by Yevhenii Matviienko on 20.11.2022.
//  Copyright © 2022 foxacid7cd. All rights reserved.
//

#import "NIUIGrid.h"
#import "NIUIGridRow.h"

@implementation NIUIGrid {
  NimsAppearance *_appearance;
  CALayer *_superlayer;

  CALayer *_layer;
  NSMutableArray<NIUIGridRow *> *_rows;
  NSMutableArray<NSMutableAttributedString *> *_attributedStrings;

  NSValue *_windowRef;
  NIGridRect _windowFrame;
}

- (instancetype)initWithAppearance:(NimsAppearance *)appearance
                        superlayer:(CALayer *)superlayer
{
  self = [super init];

  if (self) {
    _appearance = appearance;
    _superlayer = superlayer;

    _layer = [[CALayer alloc] init];
    [_layer setMasksToBounds:true];
    [_superlayer addSublayer:_layer];

    _rows = [@[] mutableCopy];
    _attributedStrings = [@[] mutableCopy];

//    _layoutManager = [[NSLayoutManager alloc] init];
//    [_layoutManager setUsesFontLeading:false];
//
//    _textStorage = [[NSTextStorage alloc] init];
//    [_textStorage addLayoutManager:_layoutManager];
//
//    _textContainer = [[NSTextContainer alloc] init];
//    [_textContainer setLineFragmentPadding:0];
//    [_textContainer setLineBreakMode:NSLineBreakByCharWrapping];
//    [_textContainer setWidthTracksTextView:true];
//    [_textContainer setHeightTracksTextView:true];
//    [_layoutManager addTextContainer:_textContainer];

//    _textView = [[NSTextView alloc] initWithFrame:NSZeroRect];
//    [_textView setEditable:false];
//    [_textView setSelectable:false];
//    [_textView setTranslatesAutoresizingMaskIntoConstraints:false];
//    [_textView setBackgroundColor:[NSColor clearColor]];
//    [_textView setHidden:true];
//
//    [[_textView layoutManager] setUsesFontLeading:false];
//
//    [[_textView textContainer] setLineFragmentPadding:0];
//    [[_textView textContainer] setLineBreakMode:NSLineBreakByCharWrapping];
//
//    [self updateTextStorage];
//    [self updateTextViewFrame];
//    [superview addSubview:_textView];
  }

  return self;
}

- (void)setSize:(NIGridSize)size
{
  _size = size;

  if (size.height > [_rows count]) {
    NSInteger delta = size.height - [_rows count];

    for (NSInteger i = 0; i < delta; i++) {
      id row = [[NIUIGridRow alloc] initWithAppearance:_appearance
                                            superlayer:_layer];
      [_rows addObject:row];

      id attributedString = [[NSMutableAttributedString alloc] init];
      [_attributedStrings addObject:attributedString];
    }
  }

  for (NSInteger rowY = 0; rowY < size.height; rowY++) {
    [_rows[rowY] setGridSize:size andRowY:rowY];

    id attributedString = _attributedStrings[rowY];

    if (size.width > [attributedString length]) {
      id string = [@"" stringByPaddingToLength:size.width - [attributedString length]
                                    withString:@" "
                               startingAtIndex:0];
      id attributes = [_appearance stringAttributesForHighlightID:0];
      [attributedString appendAttributedString:[[NSAttributedString alloc] initWithString:string
                                                                               attributes:attributes]];
    }

    [_rows[rowY] setAttributedString:_attributedStrings[rowY]];
  }

  [self updateLayerFrame];
}

- (void)setHidden:(BOOL)hidden
{
  [_layer setHidden:hidden];
}

- (void)applyRawLineAtGridY:(NSInteger)gridY
                 startGridX:(NSInteger)startGridX
                   endGridX:(NSInteger)endGridX
                 clearGridX:(NSInteger)clearGridX
             clearAttribute:(NSUInteger)clearAttribute
                      flags:(NSInteger)flags
                      chunk:(nvim_schar_t *)chunk
                 attributes:(nvim_sattr_t *)attributes
{
  NSInteger length = endGridX - startGridX;

  NSMutableString *result = [@"" mutableCopy];

  for (NSInteger i = 0; i < length; i++) {
    id string = [[NSString alloc] initWithBytes:chunk[i]
                                         length:4
                                       encoding:NSUTF32StringEncoding];

    if (string) {
      [result appendString:string];
    } else {
      [result appendString:@" "];
    }
  }

  id resultAttributedString = [[NSAttributedString alloc] initWithString:result
                                                              attributes:[_appearance stringAttributesForHighlightID:0]];
  id attributedString = _attributedStrings[gridY];
  [attributedString replaceCharactersInRange:NSMakeRange(startGridX, length)
                        withAttributedString:resultAttributedString];

  /*if (clearGridX > endGridX) {
     NSRange range = NSMakeRange(endGridX, clearGridX - endGridX);
     id string = [@"" stringByPaddingToLength:range.length
                                  withString:@" "
                             startingAtIndex:0];
     [attributedString replaceCharactersInRange:range withString:string];
     [attributedString setAttributes:[_appearance stringAttributesForHighlightID:clearAttribute]
                              range:range];
     }*/

  [_rows[gridY] setAttributedString:attributedString];
}

- (void)applyWinPosWithWindowRef:(NSValue *)windowRef
                           frame:(NIGridRect)frame
                       zPosition:(CGFloat)zPosition
{
  _windowRef = windowRef;
  _windowFrame = frame;

  [_layer setZPosition:zPosition];

  [self updateLayerFrame];

  //[_textView setHidden:false];

  //[self updateTextViewFrame];
  //[self updateTextStorage];
}

- (void)applyGridClear
{
  NSInteger rowY = 0;

  for (id attributedString in _attributedStrings) {
    NSRange range = NSMakeRange(0, [attributedString length]);
    id string = [@"" stringByPaddingToLength:range.length withString:@" " startingAtIndex:0];
    [attributedString replaceCharactersInRange:range withString:string];
    [attributedString setAttributes:[_appearance stringAttributesForHighlightID:0] range:range];

    [_rows[rowY] setAttributedString:attributedString];

    rowY++;
  }
}

- (void)updateLayerFrame
{
  NIGridRect gridFrame;

  if (_windowFrame.size.width == 0 && _windowFrame.size.height == 0) {
    gridFrame = NIGridRectMake(NIGridPointZero, _size);
  } else {
    gridFrame = _windowFrame;
  }

  CGSize cellSize = [_appearance cellSize];

  CGRect frame = CGRectMake(gridFrame.origin.x * cellSize.width,
                            gridFrame.origin.y * cellSize.height,
                            gridFrame.size.width * cellSize.width,
                            gridFrame.size.height * cellSize.height);

  [_layer setFrame:frame];
}

//- (void)updateTextStorage
//{
//  NSTextStorage *textStorage = [_textView textStorage];
//
//  [textStorage beginEditing];
//  [textStorage deleteCharactersInRange:NSMakeRange(0, [textStorage length])];
//
//  for (NSInteger gridY = 0; gridY < _size.height; NSMakeRange([textStorage ], )) {
//    nvim_grid_cell_t *row = _rows[gridY](__bridge nvim_grid_cell_t *)();
//
//    NSMutableString *currentHighlightString = [@"" mutableCopy];
//    NSInteger currentHighlightID = row[0].attr;
//
//    for (NSInteger gridX = 0; gridX < _size.width; gridX++) {
//      if (currentHighlightID == row[gridX].attr) {
//        NSString *cellText = [[NSString stringWithCString:row[gridX].data encoding:NSUTF8StringEncoding] copy];
//
//        if (cellText == nil || [cellText length] == 0) {
//          cellText = @" ";
//        }
//
//        [currentHighlightString appendString:cellText];
//      } else {
//        id attributes = [_appearance stringAttributesForHighlightID:[NSNumber numberWithInteger:currentHighlightID]];
//        id attributedString = [[NSAttributedString alloc] initWithString:currentHighlightString
//                                                              attributes:attributes];
//        [textStorage appendAttributedString:attributedString];
//
//        currentHighlightString = [@"" mutableCopy];
//        currentHighlightID = row[gridX].attr;
//      }
//    }
//
//    id attributes = [_appearance stringAttributesForHighlightID:[NSNumber numberWithInteger:currentHighlightID]];
//    id attributedString = [[NSAttributedString alloc] initWithString:currentHighlightString
//                                                          attributes:attributes];
//    [textStorage appendAttributedString:attributedString];
//
//    //[textStorage appendAttributedString:[[NSAttributedString alloc] initWithString:@"\n"]];
//  }
//
//  [textStorage endEditing];
//}

//- (void)updateTextViewFrame
//{
//  NIGridRect gridFrame;
//
//  if (_windowRef == nil) {
//    gridFrame = _frame;
//  } else {
//    gridFrame = NIGridRectMake(NIGridPointZero, _size);
//  }
//
//  CGSize cellSize = [_appearance cellSize];
//
//  CGRect frame = CGRectMake(gridFrame.origin.x * cellSize.width,
//                            gridFrame.origin.y * cellSize.height,
//                            gridFrame.size.width * cellSize.width,
//                            gridFrame.size.height * cellSize.height);
//
//  //`[[_textView textContainer] setSize:frame.size];
//  [_textView setFrame:frame];
//}

//+ (nvim_grid_cell_t **)createRowsWithSize:(NIGridSize)size
//{
//  nvim_grid_cell_t **rows = malloc(sizeof(nvim_grid_cell_t *) * size.height);
//
//  for (NSInteger gridY = 0; gridY < size.height; gridY++) {
//    size_t rowSize = sizeof(nvim_grid_cell_t) * size.width;
//    rows[gridY] = malloc(rowSize);
//
//    memset(rows[gridY], 0, rowSize);
//
//    for (NSInteger gridX = 0; gridX < size.width; gridX++) {
//      rows[gridY][gridX].data[0] = ' ';
//    }
//  }
//
//  return rows;
//}
//
//+ (void)copyRows:(nvim_grid_cell_t **)srcRows
//        withSize:(NIGridSize)srcSize
//          toRows:(nvim_grid_cell_t **)dstRows
//        withSize:(NIGridSize)dstSize
//{
//  NIGridSize size = NIGridSizeMake(MIN(srcSize.width, dstSize.width),
//                                   MIN(srcSize.height, dstSize.height));
//
//  for (NSInteger gridY = 0; gridY < size.height; gridY++) {
//    memmove(dstRows[gridY], srcRows[gridY], sizeof(nvim_grid_cell_t) * size.width);
//  }
//}
//
//+ (void)freeRows:(nvim_grid_cell_t *)rows withSize:(NIGridSize)size
//{
//  for (NSInteger gridY = 0; gridY < size.height; gridY++) {
//    free(rows[gridY]);
//  }
//
//  free(rows);
//}

@end

/*

 */
