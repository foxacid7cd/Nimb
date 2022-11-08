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

    if (type == XPC_TYPE_DICTIONARY) {
      xpc_dictionary_apply(object, ^bool(const char *key, xpc_object_t value) {
        printf("Key: %s, value: %s", key, xpc_copy_description(value));
        
        return true;
      });
    }
    
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, 5), dispatch_get_main_queue(), ^() {
      xpc_connection_cancel(connection);
    });
  });
  
  xpc_connection_resume(connection);
}

int main(int argc, char **argv)
{
  xpc_main(new_connection_handler);
}
