#define DEFINE_FUNC_ATTRIBUTES
#include "nvim/func_attr.h"
#undef DEFINE_FUNC_ATTRIBUTES
static void children_kill_cb(uv_timer_t *handle);
static void process_close_event(void **argv);
static void decref(Process *proc);
static void process_close(Process *proc) FUNC_ATTR_NONNULL_ARG(1);
static void flush_stream(Process *proc, Stream *stream) FUNC_ATTR_NONNULL_ARG(1);
static void process_close_handles(void **argv);
static void on_process_exit(Process *proc);
static void on_process_stream_close(Stream *stream, void *data);
#include "nvim/func_attr.h"
