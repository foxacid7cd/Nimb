#define DEFINE_FUNC_ATTRIBUTES
#include "nvim/func_attr.h"
#undef DEFINE_FUNC_ATTRIBUTES
static void time_event(void **argv);
static void time_watcher_cb(uv_timer_t *handle) FUNC_ATTR_NONNULL_ALL;
static void close_event(void **argv);
static void close_cb(uv_handle_t *handle) FUNC_ATTR_NONNULL_ALL;
#include "nvim/func_attr.h"
