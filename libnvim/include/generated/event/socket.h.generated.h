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
DLLEXPORT int socket_watcher_init(Loop *loop, SocketWatcher *watcher, const char *endpoint) FUNC_ATTR_NONNULL_ALL;
DLLEXPORT int socket_watcher_start(SocketWatcher *watcher, int backlog, socket_cb cb) FUNC_ATTR_NONNULL_ALL;
DLLEXPORT int socket_watcher_accept(SocketWatcher *watcher, Stream *stream) FUNC_ATTR_NONNULL_ARG(1) FUNC_ATTR_NONNULL_ARG(2);
DLLEXPORT void socket_watcher_close(SocketWatcher *watcher, socket_close_cb cb) FUNC_ATTR_NONNULL_ARG(1);
DLLEXPORT _Bool socket_connect(Loop *loop, Stream *stream, _Bool is_tcp, const char *address, int timeout, const char **error);
#include "nvim/func_attr.h"
