//
//  main.c
//  Agent
//
//  Created by Yevhenii Matviienko on 09.11.2022.
//  Copyright © 2022 foxacid7cd. All rights reserved.
//

#include <xpc/xpc.h>
#include <nvim/event/loop.h>
#include <nvim/ui_bridge.h>
#include <nvim/ui.h>
#include <uv.h>
#include "AgentLibrary.h"
#include "main.h"

extern Loop main_loop;

extern int nvim_main(int argc, char **argv);

nims_ui_bridge_dat nims_ui_data;

uv_thread_t nvim_thread;

xpc_connection_t active_xpc_connection;

void nvim_thread_entry(void *arg)
{
  char *nvim_arguments[1];
  nvim_arguments[0] = "nvim";
  //nvim_arguments[1] = "--headless";
  
  nvim_main(1, nvim_arguments);
}



void handle_input_message_data(xpc_object_t data)
{
  int64_t message_type = xpc_array_get_int64(data, 0);
  
  switch (message_type) {
    case AgentInputMessageTypeStart: {
      nims_ui_data.init_width = (int) xpc_array_get_int64(data, 1);
      nims_ui_data.init_height = (int) xpc_array_get_int64(data, 2);
      
      uv_thread_create(&nvim_thread, nvim_thread_entry, NULL);
    }
      
    default:
      break;
  }
}

void handle_connection(xpc_connection_t connection)
{
  if (active_xpc_connection != NULL) {
    return xpc_connection_cancel(connection);
  }
  
  active_xpc_connection = connection;
  
  xpc_connection_set_event_handler(connection, ^(xpc_object_t object) {
    xpc_type_t type = xpc_get_type(object);
    
    if (type == XPC_TYPE_ERROR) {
      const char *description = xpc_dictionary_get_string(object, XPC_ERROR_KEY_DESCRIPTION);
      printf("XPC error: %s\n", description);
  
      return;
    }
    
    xpc_object_t data = xpc_dictionary_get_array(object, AGENT_MESSAGE_DATA_KEY);
    handle_input_message_data(data);
    
    xpc_object_t reply_data = xpc_array_create_empty();
    xpc_array_append_value(reply_data, xpc_bool_create(true));
    
    xpc_object_t reply_message = xpc_dictionary_create_reply(object);
    xpc_dictionary_set_value(reply_message, AGENT_MESSAGE_DATA_KEY, reply_data);
    
    xpc_connection_send_message(connection, reply_message);
  });
  
  xpc_connection_activate(connection);
}

int main(int argc, char **argv)
{
  xpc_main(handle_connection);
}
