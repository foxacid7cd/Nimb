#define DEFINE_FUNC_ATTRIBUTES
#include "nvim/func_attr.h"
#undef DEFINE_FUNC_ATTRIBUTES
static void loop_deferred_event(void **argv);
static void loop_walk_cb(uv_handle_t *handle, void *arg);
static void async_cb(uv_async_t *handle);
static void timer_cb(uv_timer_t *handle);
static void timer_close_cb(uv_handle_t *handle);
#include "nvim/func_attr.h"
