//
//  main.c
//  Agent
//
//  Created by Yevhenii Matviienko on 09.11.2022.
//  Copyright © 2022 foxacid7cd. All rights reserved.
//

#include <xpc/xpc.h>
#include <nvim_main.h>
#include <nvim/ui_bridge.h>
#include <uv.h>
#include "AgentLibrary.h"
#include "main.h"

uv_thread_t nvim_thread;

void handle_connection(xpc_connection_t connection)
{
  xpc_connection_set_event_handler(connection, ^(xpc_object_t object) {
    xpc_type_t type = xpc_get_type(object);
    
    if (type == XPC_TYPE_ERROR) {
      const char *description = xpc_dictionary_get_string(object, XPC_ERROR_KEY_DESCRIPTION);
      printf("XPC error: %s\n", description);
  
      return;
    }
    
    xpc_object_t data = xpc_array_create_empty();
    xpc_array_append_value(data, xpc_bool_create(true));
    
    xpc_object_t reply_message = xpc_dictionary_create_reply(object);
    xpc_dictionary_set_value(reply_message, AGENT_MESSAGE_DATA_KEY, data);
    
    xpc_connection_send_message(connection, reply_message);
  });
  
  xpc_connection_activate(connection);
}

void nvim_thread_entry(void *arg)
{
  char *nvim_arguments[2];
  nvim_arguments[0] = "nvim";
  nvim_arguments[1] = "--headless";
  
  nvim_main(2, nvim_arguments);
}

int main(int argc, char **argv)
{
  uv_thread_create(&nvim_thread, nvim_thread_entry, NULL);
  
  xpc_main(handle_connection);
}
