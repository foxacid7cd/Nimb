//
//  NIUIGrid.m
//  Nims
//
//  Created by Yevhenii Matviienko on 20.11.2022.
//  Copyright © 2022 foxacid7cd. All rights reserved.
//

#import "NIUIGrid.h"

@implementation NIUIGrid {
  NimsAppearance *_appearance;

  NSTextStorage *_textStorage;
  NSLayoutManager *_layoutManager;
  NSTextContainer *_textContainer;
  NSTextView *_textView;

  nvim_grid_cell_t **_rows;

  NSNumber *_windowRef;
  NIGridRect _frame;
  CGFloat _zPosition;
}

- (instancetype)initWithAppearance:(NimsAppearance *)appearance
                           andSize:(NIGridSize)size
{
  self = [super init];

  if (self) {
    _appearance = appearance;

    _textStorage = [[NSTextStorage alloc] init];
    _layoutManager = [[NSLayoutManager alloc] init];
    [_textStorage addLayoutManager:_layoutManager];
    _textContainer = [[NSTextContainer alloc] init];
    [_textContainer setLineFragmentPadding:0];
    [_textContainer setLineBreakMode:NSLineBreakByCharWrapping];
    [_textContainer setWidthTracksTextView:true];
    [_textContainer setHeightTracksTextView:true];
    [_layoutManager addTextContainer:_textContainer];
    _textView = [[NSTextView alloc] initWithFrame:NSZeroRect
                                    textContainer:_textContainer];
    [_textView setEditable:false];
    [_textView setSelectable:false];

    [self setSize:size];
  }

  return self;
}

- (void)dealloc
{
  [NIUIGrid freeRows:_rows withSize:_size];
}

- (void)setSize:(NIGridSize)size
{
  nvim_grid_cell_t **rows = [NIUIGrid createRowsWithSize:size];

  if (_rows) {
    [NIUIGrid copyRows:_rows withSize:_size toRows:rows withSize:size];
  }

  _size = size;
  _rows = rows;

  [self updateTextContainerSize];
  [self updateTextStorage];
}

- (void)applyRawLineAtGridY:(NSInteger)gridY
                 startGridX:(NSInteger)startGridX
                   endGridX:(NSInteger)endGridX
                 clearGridX:(NSInteger)clearGridX
             clearAttribute:(NSNumber *)clearAttribute
                      flags:(NSInteger)flags
                      chunk:(nvim_schar_t *)chunk
                 attributes:(nvim_sattr_t *)attributes
{
  nvim_grid_cell_t *row = _rows[gridY];

  NSInteger length = endGridX - startGridX;

  for (NSInteger i = 0; i < length; i++) {
    NSInteger gridX = i + startGridX;

    memcpy(row[gridX].data, chunk[i], sizeof(nvim_schar_t));
    row[gridX].attr = attributes[i];
  }

  [self updateTextStorage];
}

- (void)applyWinPosWithWindowRef:(NSNumber *)windowRef
                           frame:(NIGridRect)frame
                       zPosition:(CGFloat)zPosition
{
  _windowRef = windowRef;
  _frame = frame;
  _zPosition = zPosition;

  [_textView setHidden:false];
  [self updateTextContainerSize];
}

- (NSView *)view
{
  return _textView;
}

- (void)updateTextStorage
{
  NSMutableAttributedString *gridAttributedString = [[NSMutableAttributedString alloc] init];

  for (NSInteger gridY = 0; gridY < _size.height; gridY++) {
    nvim_grid_cell_t *row = _rows[gridY];

    NSMutableString *currentHighlightString = [@"" mutableCopy];
    NSInteger currentHighlightID = row[0].attr;

    for (NSInteger gridX = 0; gridX < _size.width; gridX++) {
      if (currentHighlightID == row[gridX].attr) {
        NSString *cellText = [NSString stringWithUTF8String:row[gridX].data];

        if ([cellText length] > 0) {
          [currentHighlightString appendString:cellText];
        }
      } else {
        id attributes = [_appearance stringAttributesForHighlightID:[NSNumber numberWithInteger:currentHighlightID]];
        id attributedString = [[NSAttributedString alloc] initWithString:currentHighlightString
                                                              attributes:attributes];
        [gridAttributedString appendAttributedString:attributedString];

        currentHighlightString = [@"" mutableCopy];
        currentHighlightID = row[gridX].attr;
      }
    }

    id attributes = [_appearance stringAttributesForHighlightID:[NSNumber numberWithInteger:currentHighlightID]];
    id attributedString = [[NSAttributedString alloc] initWithString:currentHighlightString
                                                          attributes:attributes];
    [gridAttributedString appendAttributedString:attributedString];

    //[gridAttributedString appendAttributedString:[[NSAttributedString alloc] initWithString:@"\n"]];
  }

  [_textStorage setAttributedString:gridAttributedString];
}

- (void)updateTextContainerSize
{
  NIGridSize size;

  if (_windowRef == nil) {
    size = _size;
  } else {
    size = _frame.size;
  }

  CGSize cellSize = [_appearance cellSize];
  [_textContainer setSize:NSMakeSize(size.width * cellSize.width,
                                     size.height * cellSize.height)];
}

+ (nvim_grid_cell_t **)createRowsWithSize:(NIGridSize)size
{
  nvim_grid_cell_t **rows = malloc(sizeof(nvim_grid_cell_t *) * size.height);

  for (NSInteger gridY = 0; gridY < size.height; gridY++) {
    rows[gridY] = malloc(sizeof(nvim_grid_cell_t) * size.width);

    nvim_grid_cell_t *row = rows[gridY];

    for (NSInteger gridX = 0; gridX < size.width; gridX++) {
      row[gridX].data[0] = ' ';
      row[gridX].data[1] = 0;
      row[gridX].attr = 0;
    }
  }

  return rows;
}

+ (void)copyRows:(nvim_grid_cell_t **)srcRows
        withSize:(NIGridSize)srcSize
          toRows:(nvim_grid_cell_t **)dstRows
        withSize:(NIGridSize)dstSize
{
  NIGridSize size = NIGridSizeMake(MIN(srcSize.width, dstSize.width),
                                   MIN(srcSize.height, dstSize.height));

  for (NSInteger gridY = 0; gridY < size.height; gridY++) {
    memcpy(dstRows[gridY], srcRows[gridY], sizeof(nvim_grid_cell_t) * size.width);
  }
}

+ (void)freeRows:(nvim_grid_cell_t **)rows withSize:(NIGridSize)size
{
  for (NSInteger gridY = 0; gridY < size.height; gridY++) {
    free(rows[gridY]);
  }

  free(rows);
}

@end
