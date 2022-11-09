#define DEFINE_FUNC_ATTRIBUTES
#include "nvim/func_attr.h"
#undef DEFINE_FUNC_ATTRIBUTES
static void write_cb(uv_write_t *req, int status);
#include "nvim/func_attr.h"
