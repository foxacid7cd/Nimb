//
//  NimsUIHighlights.h
//  Nims
//
//  Created by Yevhenii Matviienko on 18.11.2022.
//  Copyright © 2022 foxacid7cd. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "HighlightAttributes.h"

NS_ASSUME_NONNULL_BEGIN

@interface NimsUIHighlights : NSObject

- (void)setDefaultAttributes:(HighlightAttributes *)defaultAttributes;
- (HighlightAttributes *)defaultAttributes;
- (void)setAttributes:(HighlightAttributes *)attributes forID:(int64_t)_id;
- (HighlightAttributes *)attributesForID:(int64_t)_id;
- (void)setName:(NSString *)name forID:(int64_t)_id;

@end

NS_ASSUME_NONNULL_END
