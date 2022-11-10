//
//  main.h
//  Agent
//
//  Created by Yevhenii Matviienko on 09.11.2022.
//  Copyright © 2022 foxacid7cd. All rights reserved.
//

#ifndef main_h
#define main_h

#include <CoreFoundation/CoreFoundation.h>

typedef struct {
  UIBridgeData *bridge;
  Loop *loop;
  
  bool stop;
  
  int init_width;
  int init_height;
} nims_ui_bridge_dat;

extern nims_ui_bridge_dat nims_ui_data;

#endif /* main_h */
