#define DEFINE_FUNC_ATTRIBUTES
#include "nvim/func_attr.h"
#undef DEFINE_FUNC_ATTRIBUTES
static _Bool check_string_array(Array arr, _Bool disallow_nl, Error *err);
static void fix_cursor(linenr_T lo, linenr_T hi, linenr_T extra);
static int64_t normalize_index(buf_T *buf, int64_t index, _Bool end_exclusive, _Bool *oob);
#include "nvim/func_attr.h"
