#define DEFINE_FUNC_ATTRIBUTES
#include "nvim/func_attr.h"
#undef DEFINE_FUNC_ATTRIBUTES
static void close_cb(uv_handle_t *handle);
static void exit_cb(uv_process_t *handle, int64_t status, int term_signal);
#include "nvim/func_attr.h"
