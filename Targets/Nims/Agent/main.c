//
//  main.c
//  Agent
//
//  Created by Yevhenii Matviienko on 09.11.2022.
//  Copyright © 2022 foxacid7cd. All rights reserved.
//

#include <xpc/xpc.h>
#include <nvim_main.h>
#include "AgentLibrary.h"

void handle_connection(xpc_connection_t connection)
{
  xpc_connection_set_event_handler(connection, ^(xpc_object_t object) {
    xpc_type_t type = xpc_get_type(object);
    
    if (type == XPC_TYPE_ERROR) {
      const char *description = xpc_dictionary_get_string(object, XPC_ERROR_KEY_DESCRIPTION);
      
      printf("XPC error: %s\n", description);
      
    } else if (type == XPC_TYPE_DICTIONARY) {
      xpc_object_t data = xpc_dictionary_get_array(object, AGENT_MESSAGE_DATA_KEY);
      
      int64_t message_id = xpc_array_get_int64(data, 0);
      
      printf("XPC received message with id: %llu\n", message_id);
      
    } else {
      printf("Dictionary XPC object expected, but got %s\n", xpc_type_get_name(type));
    }
  });
}

int main(int argc, char **argv)
{  
  xpc_main(handle_connection);
}
