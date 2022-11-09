#define DEFINE_FUNC_ATTRIBUTES
#include "nvim/func_attr.h"
#undef DEFINE_FUNC_ATTRIBUTES
static void arena_free_reuse_blks(void);
static size_t arena_align_offset(uint64_t off);
#include "nvim/func_attr.h"
