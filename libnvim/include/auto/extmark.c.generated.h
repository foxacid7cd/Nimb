#define DEFINE_FUNC_ATTRIBUTES
#include "nvim/func_attr.h"
#undef DEFINE_FUNC_ATTRIBUTES
static uint32_t *buf_ns_ref(buf_T *buf, uint32_t ns_id, _Bool put);
static _Bool extmark_setraw(buf_T *buf, uint64_t mark, int row, colnr_T col);
static void u_extmark_set(buf_T *buf, uint64_t mark, int row, colnr_T col);
#include "nvim/func_attr.h"
