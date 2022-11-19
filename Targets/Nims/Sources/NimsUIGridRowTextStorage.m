//
//  NimsUIGridRowTextStorage.m
//  Nims
//
//  Created by Yevhenii Matviienko on 19.11.2022.
//  Copyright © 2022 foxacid7cd. All rights reserved.
//

#import "NSAttributedString+NimsUI.h"
#import "NimsUIGridRowTextStorage.h"

@implementation NimsUIGridRowTextStorage {
  NimsUIHighlights* _highlights;
  NimsFont *_font;
  NSMutableAttributedString *_backingStore;
}

- (instancetype)initWithHighlights:(NimsUIHighlights *)highlights font:(NimsFont *)font gridWidth:(NSInteger)gridWidth;
{
  self = [super init];
  if (self != nil) {
    self->_highlights = highlights;
    self->_font = font;
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
    id attributes = @{
      HighlightIDAttributeName:[NSNumber numberWithLongLong:0],
      NSFontAttributeName:[self->_font regular],
      NSForegroundColorAttributeName:[self->_highlights defaultRGBForegroundColor],
      NSBackgroundColorAttributeName:[self->_highlights defaultRGBBackgroundColor],
      NSParagraphStyleAttributeName:[self->_font paragraphStyle],
      NSLigatureAttributeName:[NSNumber numberWithInt:2]
    };
    id attributedString = [[NSAttributedString alloc] initWithString:additionalString attributes:attributes];
    [self->_backingStore appendAttributedString:attributedString];
    
    [self edited:NSTextStorageEditedCharacters | NSTextStorageEditedAttributes
           range:NSMakeRange(0, initialLength)
  changeInLength:delta];
    
  } else {
    NSRange rangeToDelete = NSMakeRange([self->_backingStore length] + delta, -delta);
    [self->_backingStore deleteCharactersInRange:rangeToDelete];
    
    [self edited:NSTextStorageEditedCharacters | NSTextStorageEditedCharacters
           range:rangeToDelete
  changeInLength:delta];
  }
}

- (void)setString:(NSString *)string withHighlightID:(NSNumber *)highlightID atIndex:(NSUInteger)index
{
  NSRange range = NSMakeRange(index, [string length]);
  id attributes = @{
    HighlightIDAttributeName:highlightID,
    NSFontAttributeName:[self->_highlights pickFont:self->_font forHighlightID:highlightID],
    NSForegroundColorAttributeName:[self->_highlights foregroundColorForHighlightID:highlightID],
    NSBackgroundColorAttributeName:[self->_highlights backgroundColorForHighlightID:highlightID],
    NSParagraphStyleAttributeName:[self->_font paragraphStyle],
    NSLigatureAttributeName:[NSNumber numberWithInt:2]
  };
  [self->_backingStore replaceCharactersInRange:range withString:string];
  [self->_backingStore setAttributes:attributes range:range];
  
  [self edited:NSTextStorageEditedCharacters | NSTextStorageEditedAttributes
         range:range
changeInLength:0];
}

- (void)clearText
{
  [self beginEditing];
  
  NSUInteger length = [self->_backingStore length];
  [self setGridWidth:0];
  [self setGridWidth:length];
  
  [self endEditing];
}

- (void)highlightsUpdated
{
  [self->_backingStore enumerateAttributesInRange:NSMakeRange(0, [self->_backingStore length]) options:0 usingBlock:^(NSDictionary<NSAttributedStringKey, id> *attrs, NSRange range, BOOL *stop) {
    NSNumber *highlightID = [attrs objectForKey:HighlightIDAttributeName];
    
    NSMutableDictionary<NSAttributedStringKey, id> *newAttrs = [attrs mutableCopy];
    [newAttrs setObject:[self->_highlights pickFont:self->_font forHighlightID:highlightID] forKey:NSFontAttributeName];
    [newAttrs setObject:[self->_highlights foregroundColorForHighlightID:highlightID] forKey:NSForegroundColorAttributeName];
    [newAttrs setObject:[self->_highlights backgroundColorForHighlightID:highlightID] forKey:NSBackgroundColorAttributeName];
    
    [self->_backingStore setAttributes:newAttrs range:range];
  }];
  
  [self edited:NSTextStorageEditedAttributes
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
  
  [self edited:NSTextStorageEditedCharacters
         range:range
changeInLength:([string length] - range.length)];
}

- (void)setAttributes:(NSDictionary *)attrs range:(NSRange)range
{
  [self->_backingStore setAttributes:attrs range:range];
  
  [self edited:NSTextStorageEditedAttributes
         range:range
changeInLength:0];
}



@end
