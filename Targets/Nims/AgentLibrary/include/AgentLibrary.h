//
//  AgentLibrary.h
//  AgentLibrary
//
//  Created by Yevhenii Matviienko on 09.11.2022.
//  Copyright © 2022 foxacid7cd. All rights reserved.
//

#ifndef AgentLibrary_h
#define AgentLibrary_h

#include <stdio.h>

#define AGENT_MESSAGE_DATA_KEY "data"

typedef enum : int64_t {
  AgentNvimReady,
  AgentWindowFrameChanged,
  AgentGridLineChanged
} agent_message_type_t;

typedef enum : int32_t {
  AgentInputMessageTypeRun
} agent_input_message_type_t;

#endif /* AgentLibrary_h */
