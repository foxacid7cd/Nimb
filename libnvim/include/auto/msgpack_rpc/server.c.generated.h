#define DEFINE_FUNC_ATTRIBUTES
#include "nvim/func_attr.h"
#undef DEFINE_FUNC_ATTRIBUTES
static void close_socket_watcher(SocketWatcher **watcher);
static void set_vservername(garray_T *srvs);
static void connection_cb(SocketWatcher *watcher, int result, void *data);
static void free_server(SocketWatcher *watcher, void *data);
#include "nvim/func_attr.h"
