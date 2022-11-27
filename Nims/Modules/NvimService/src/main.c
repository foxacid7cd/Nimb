
#include <os/log.h>
#include <xpc/xpc.h>

int nvim_main(int argc, char **argv) {
  os_log(OS_LOG_TYPE_DEFAULT, "nvim_main %i", argc);

  for (int i = 0; i < argc; i++) {
    os_log(OS_LOG_TYPE_DEFAULT, "arg %s", argv[i]);
  }
}

static void handle_connection(xpc_connection_t connection) {
  xpc_retain(connection);

  xpc_connection_set_event_handler(connection, ^(xpc_object_t object) {
    xpc_type_t type = xpc_get_type(object);

    if (type == XPC_TYPE_ERROR) {
      char *description =
          xpc_dictionary_get_string(object, XPC_ERROR_KEY_DESCRIPTION);
      os_log(OS_LOG_DEFAULT, "XPC error: %s", description);

      xpc_release(connection);
      return;
    }

    const char *method = xpc_dictionary_get_string(object, "method");
    if (strcmp(method, "start") == 0) {
      xpc_object_t arguments = xpc_dictionary_get_array(object, "arguments");

      size_t argc = xpc_array_get_count(arguments);

      char **argv = malloc(sizeof(char *) * argc);
      for (size_t i = 0; i < argc; i++) {
        argv[i] = xpc_array_get_string(arguments, i);
      }

      nvim_main(argc, argv);
    }
  });

  xpc_connection_activate(connection);
}

int main(int argc, char **argv) { xpc_main(handle_connection); }
