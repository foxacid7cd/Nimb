//
//  NimsUI.h
//  Nims
//
//  Created by Yevhenii Matviienko on 11.11.2022.
//  Copyright © 2022 foxacid7cd. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "MainWindow.h"

NS_ASSUME_NONNULL_BEGIN

@interface NimsUI : NSObject

- (instancetype)initWithMainWindow:(MainWindow *)mainWindow;

- (void)start;

@end

NS_ASSUME_NONNULL_END
