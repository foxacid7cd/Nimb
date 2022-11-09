#define DEFINE_FUNC_ATTRIBUTES
#include "nvim/func_attr.h"
#undef DEFINE_FUNC_ATTRIBUTES
static void changed_common(linenr_T lnum, colnr_T col, linenr_T lnume, linenr_T xtra);
static void changedOneline(buf_T *buf, linenr_T lnum);
#include "nvim/func_attr.h"
