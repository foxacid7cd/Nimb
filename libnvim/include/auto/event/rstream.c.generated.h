#define DEFINE_FUNC_ATTRIBUTES
#include "nvim/func_attr.h"
#undef DEFINE_FUNC_ATTRIBUTES
static void on_rbuffer_full(RBuffer *buf, void *data);
static void on_rbuffer_nonfull(RBuffer *buf, void *data);
static void alloc_cb(uv_handle_t *handle, size_t suggested, uv_buf_t *buf);
static void read_cb(uv_stream_t *uvstream, ssize_t cnt, const uv_buf_t *buf);
static void fread_idle_cb(uv_idle_t *handle);
static void read_event(void **argv);
static void invoke_read_cb(Stream *stream, size_t count, _Bool eof);
#include "nvim/func_attr.h"
