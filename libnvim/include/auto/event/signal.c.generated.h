#define DEFINE_FUNC_ATTRIBUTES
#include "nvim/func_attr.h"
#undef DEFINE_FUNC_ATTRIBUTES
static void signal_event(void **argv);
static void signal_watcher_cb(uv_signal_t *handle, int signum);
static void close_cb(uv_handle_t *handle);
#include "nvim/func_attr.h"
