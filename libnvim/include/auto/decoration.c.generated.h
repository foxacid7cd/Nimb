#define DEFINE_FUNC_ATTRIBUTES
#include "nvim/func_attr.h"
#undef DEFINE_FUNC_ATTRIBUTES
static _Bool decor_virt_pos(Decoration decor);
static void decor_add(DecorState *state, int start_row, int start_col, int end_row, int end_col, Decoration *decor, _Bool owned, uint64_t ns_id, uint64_t mark_id);
#include "nvim/func_attr.h"
