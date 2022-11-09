#define DEFINE_FUNC_ATTRIBUTES
#include "nvim/func_attr.h"
#undef DEFINE_FUNC_ATTRIBUTES
static void find_runtime_cb(char *fname, void *cookie);
static void term_write(char *buf, size_t size, void *data);
static void term_resize(uint16_t width, uint16_t height, void *data);
static void term_close(void *data);
static void write_msg(String message, _Bool to_err);
#include "nvim/func_attr.h"
