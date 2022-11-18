//
//  NimsUIHighlights.m
//  Nims
//
//  Created by Yevhenii Matviienko on 18.11.2022.
//  Copyright © 2022 foxacid7cd. All rights reserved.
//

#import "NimsUIHighlights.h"

@implementation NimsUIHighlights {
  NSMutableDictionary<NSNumber *, HighlightAttributes *> *_attributes;
  HighlightAttributes *_defaultAttributes;
  NSMutableDictionary<NSNumber *, NSString *> *_names;
}

- (instancetype)init
{
  self = [super init];
  if (self != nil) {
    self->_attributes = [@{} mutableCopy];
    self->_defaultAttributes = [[HighlightAttributes alloc] initWithFlags:0
                                                             rgbForegound:0xFF0000
                                                            rgbBackground:0x0000FF
                                                               rgbSpecial:0x00FF00
                                                          ctermForeground:5
                                                          ctermBackground:250
                                                                    blend:0];
    self->_names = [@{} mutableCopy];
  }
  return self;
}

- (void)setDefaultAttributes:(HighlightAttributes *)defaultAttributes
{
  self->_defaultAttributes = defaultAttributes;
}

- (HighlightAttributes *)defaultAttributes
{
  return self->_defaultAttributes;
}

- (void)setAttributes:(HighlightAttributes *)attributes forID:(int64_t)_id
{
  [self->_attributes setObject:attributes
                        forKey:[NSNumber numberWithLongLong:_id]];
}

- (HighlightAttributes *)attributesForID:(int64_t)_id
{
  return [self->_attributes objectForKey:[NSNumber numberWithLongLong:_id]];
}

- (void)setName:(NSString *)name forID:(int64_t)_id
{
  [self->_names setObject:name forKey:[NSNumber numberWithLongLong:_id]];
}

@end
