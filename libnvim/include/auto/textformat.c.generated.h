#define DEFINE_FUNC_ATTRIBUTES
#include "nvim/func_attr.h"
#undef DEFINE_FUNC_ATTRIBUTES
static int fmt_check_par(linenr_T lnum, int *leader_len, char_u **leader_flags, _Bool do_comments);
static _Bool ends_in_white(linenr_T lnum);
static _Bool same_leader(linenr_T lnum, int leader1_len, char *leader1_flags, int leader2_len, char *leader2_flags);
static _Bool paragraph_start(linenr_T lnum);
#include "nvim/func_attr.h"
