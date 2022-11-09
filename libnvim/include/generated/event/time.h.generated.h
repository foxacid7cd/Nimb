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
DLLEXPORT void time_watcher_init(Loop *loop, TimeWatcher *watcher, void *data) FUNC_ATTR_NONNULL_ARG(1) FUNC_ATTR_NONNULL_ARG(2);
DLLEXPORT void time_watcher_start(TimeWatcher *watcher, time_cb cb, uint64_t timeout, uint64_t repeat) FUNC_ATTR_NONNULL_ALL;
DLLEXPORT void time_watcher_stop(TimeWatcher *watcher) FUNC_ATTR_NONNULL_ALL;
DLLEXPORT void time_watcher_close(TimeWatcher *watcher, time_cb cb) FUNC_ATTR_NONNULL_ARG(1);
#include "nvim/func_attr.h"
