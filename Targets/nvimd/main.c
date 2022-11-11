//
//  main.c
//  Agent
//
//  Created by Yevhenii Matviienko on 09.11.2022.
//  Copyright © 2022 foxacid7cd. All rights reserved.
//

#include <xpc/xpc.h>
#include <uv.h>

extern int nvim_main(int argc, char **argv);

uv_thread_t nvim_thread;

void nvim_thread_main(void *arg)
{
  char *argv0 = "nvimd";
  nvim_main(1, &argv0);
}

xpc_connection_t active_connection;

void handle_connection(xpc_connection_t connection)
{
  if (active_connection != NULL) {
    return xpc_connection_cancel(connection);
  }
  
  xpc_retain(connection);
  active_connection = connection;
  
  xpc_connection_set_event_handler(connection, ^(xpc_object_t object) {
    xpc_type_t type = xpc_get_type(object);
    
    if (type == XPC_TYPE_ERROR) {
      const char *description = xpc_dictionary_get_string(object, XPC_ERROR_KEY_DESCRIPTION);
      printf("XPC error: %s\n", description);
  
      return;
    }
    
    int64_t message_type = xpc_dictionary_get_int64(object, "type");
    switch (message_type) {
      case 0: {
        uv_thread_create(&nvim_thread, nvim_thread_main, NULL);
      }
        
      default:
        break;
    }
  });
  
  xpc_connection_activate(connection);
}

int main(int argc, char **argv)
{
  xpc_main(handle_connection);
}
