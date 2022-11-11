//
//  AppDelegate.m
//  Nims
//
//  Created by Yevhenii Matviienko on 10.11.2022.
//  Copyright © 2022 foxacid7cd. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@interface AppDelegate : NSObject <NSApplicationDelegate> {
  xpc_connection_t active_connection;
}

@end

@implementation AppDelegate

- (void)applicationDidBecomeActive:(NSNotification *)notification
{
  xpc_connection_t connection = xpc_connection_create("foxacid7cd.Nims.nvimd", NULL);
  self->active_connection = connection;
  
  xpc_connection_set_event_handler(connection, ^(xpc_object_t object) {
    xpc_type_t type = xpc_get_type(object);
    
    if (type == XPC_TYPE_ERROR) {
      const char *description = xpc_dictionary_get_string(object, XPC_ERROR_KEY_DESCRIPTION);
      
      NSLog(@"XPC error: %s", description);
      return;
    }
    
    int64_t message_type = xpc_dictionary_get_int64(object, "type");
    switch (message_type) {
      case 0:
        NSLog(@"Started!");
        
      default:
        break;
    }
  });
  
  xpc_connection_activate(connection);
  
  xpc_object_t message = xpc_dictionary_create_empty();
  xpc_dictionary_set_int64(message, "type", 0);
  xpc_connection_send_message(connection, message);
}

@end
