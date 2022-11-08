//
//  main.c
//  Agent
//
//  Created by Yevhenii Matviienko on 08.11.2022.
//  Copyright © 2022 foxacid7cd. All rights reserved.
//

#include "main.h"

static void new_connection_handler(xpc_connection_t connection)
{
  xpc_connection_set_event_handler(connection, ^(xpc_object_t object) {
    xpc_type_t type = xpc_get_type(object);
    const char *name = xpc_type_get_name(type);
    printf("Received xpc object with name: %s", name);
  });
  
  xpc_connection_resume(connection);
}

int main(int argc, const char **argv)
{
  start_nvim();
  
  xpc_main(new_connection_handler);
}
