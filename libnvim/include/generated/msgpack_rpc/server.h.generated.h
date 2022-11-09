#define DEFINE_FUNC_ATTRIBUTES
#include "nvim/func_attr.h"
#undef DEFINE_FUNC_ATTRIBUTES
#ifndef DLLEXPORT
#  ifdef MSWIN
#    define DLLEXPORT __declspec(dllexport)
#  else
#    define DLLEXPORT
#  endif
#endif
DLLEXPORT _Bool server_init(const char *listen_addr);
DLLEXPORT void server_teardown(void);
DLLEXPORT char *server_address_new(const char *name);
DLLEXPORT _Bool server_owns_pipe_address(const char *path);
DLLEXPORT int server_start(const char *addr);
DLLEXPORT _Bool server_stop(char *endpoint);
DLLEXPORT char **server_address_list(size_t *size) FUNC_ATTR_NONNULL_ALL;
#include "nvim/func_attr.h"
