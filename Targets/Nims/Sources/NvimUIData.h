//
//  NvimUIData.h
//  Nims
//
//  Created by Yevhenii Matviienko on 11.11.2022.
//  Copyright © 2022 foxacid7cd. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "NvimWindow.h"

NS_ASSUME_NONNULL_BEGIN

@interface NvimUIData : NSObject

- (instancetype)initWithBridge:(void *)bridge andLoop:(void *)loop;

@property (nonatomic, copy) NSArray<NvimWindow *> *windows;

- (void *)loop;

@end

NS_ASSUME_NONNULL_END
