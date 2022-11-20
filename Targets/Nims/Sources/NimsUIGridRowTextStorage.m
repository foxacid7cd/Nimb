//
//  NimsUIGridRowTextStorage.m
//  Nims
//
//  Created by Yevhenii Matviienko on 19.11.2022.
//  Copyright © 2022 foxacid7cd. All rights reserved.
//

#import "NimsUIGridRowTextStorage.h"
#import "NSAttributedString+NimsUI.h"

@implementation NimsUIGridRowTextStorage {
  NimsAppearance *_appearance;
  NSMutableAttributedString *_backingStore;
}

- (instancetype)initWithAppearance:(NimsAppearance *)appearance gridWidth:(NSInteger)gridWidth
{
  self = [super init];

  if (self != nil) {
    self->_appearance = appearance;
    self->_backingStore = [[NSMutableAttributedString alloc] init];

    [self setGridWidth:gridWidth];
  }

  return self;
}

- (void)setGridWidth:(NSInteger)gridWidth
{
  NSInteger delta = gridWidth - [self->_backingStore length];

  if (delta > 0) {
    NSInteger initialLength = [self->_backingStore length];
    id additionalString = [@"" stringByPaddingToLength:delta
                                            withString:@" "
                                       startingAtIndex:0];
    id attributes = [self->_appearance stringAttributesForHighlightID:[NimsAppearance defaultHighlightID]];
    id attributedString = [[NSAttributedString alloc] initWithString:additionalString
                                                          attributes:attributes];
    [self->_backingStore appendAttributedString:attributedString];

    [self     edited:NSTextStorageEditedCharacters | NSTextStorageEditedAttributes
               range:NSMakeRange(0, initialLength)
      changeInLength:delta];
  } else {
    NSRange rangeToDelete = NSMakeRange([self->_backingStore length] + delta, -delta);
    [self->_backingStore deleteCharactersInRange:rangeToDelete];

    [self     edited:NSTextStorageEditedCharacters | NSTextStorageEditedCharacters
               range:rangeToDelete
      changeInLength:delta];
  }
}

- (void)setString:(NSString *)string withHighlightID:(NSNumber *)highlightID atIndex:(NSUInteger)index
{
  NSRange range = NSMakeRange(index, [string length]);

  [self->_backingStore replaceCharactersInRange:range
                                     withString:string];
  [self->_backingStore setAttributes:[self->_appearance stringAttributesForHighlightID:highlightID]
                               range:range];

  [self     edited:NSTextStorageEditedCharacters | NSTextStorageEditedAttributes
             range:range
    changeInLength:0];
}

- (void)clearText
{
  NSRange range = NSMakeRange(0, [self->_backingStore length]);
  id clearString = [@"" stringByPaddingToLength:range.length
                                     withString:@" "
                                startingAtIndex:0];
  id attributes = [self->_appearance stringAttributesForHighlightID:[NimsAppearance defaultHighlightID]];
  id attributedString = [[NSAttributedString alloc] initWithString:clearString
                                                        attributes:attributes];

  [self->_backingStore setAttributedString:attributedString];

  [self     edited:NSTextStorageEditedCharacters | NSTextStorageEditedAttributes
             range:range
    changeInLength:0];
}

- (void)highlightsUpdated
{
  [self->_backingStore enumerateAttributesInRange:NSMakeRange(0, [self->_backingStore length])
                                          options:0
                                       usingBlock:^(NSDictionary<NSAttributedStringKey, id> *attrs, NSRange range, BOOL *stop) {
    NSNumber *highlightID = [attrs objectForKey:HighlightIDAttributeName];

    [self->_backingStore setAttributes:[self->_appearance stringAttributesForHighlightID:highlightID]
                                 range:range];
  }];

  [self     edited:NSTextStorageEditedAttributes
             range:NSMakeRange(0, [self->_backingStore length])
    changeInLength:0];
}

- (NSString *)string
{
  return self->_backingStore.string;
}

- (NSDictionary *)attributesAtIndex:(NSUInteger)location effectiveRange:(NSRangePointer)range
{
  return [self->_backingStore attributesAtIndex:location effectiveRange:range];
}

- (void)replaceCharactersInRange:(NSRange)range withString:(NSString *)string
{
  [self->_backingStore replaceCharactersInRange:range withString:string];

  [self     edited:NSTextStorageEditedCharacters
             range:range
    changeInLength:([string length] - range.length)];
}

- (void)setAttributes:(NSDictionary *)attrs range:(NSRange)range
{
  [self->_backingStore setAttributes:attrs range:range];

  [self     edited:NSTextStorageEditedAttributes
             range:range
    changeInLength:0];
}

@end
