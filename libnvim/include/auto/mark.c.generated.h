#define DEFINE_FUNC_ATTRIBUTES
#include "nvim/func_attr.h"
#undef DEFINE_FUNC_ATTRIBUTES
static MarkMoveRes switch_to_mark_buf(fmark_T *fm, _Bool pcmark_on_switch);
static void fname2fnum(xfmark_T *fm);
static void fmarks_check_one(xfmark_T *fm, char *name, buf_T *buf);
static char *mark_line(pos_T *mp, int lead_len);
static void show_one_mark(int c, char_u *arg, pos_T *p, char_u *name_arg, int current);
static void mark_adjust_internal(linenr_T line1, linenr_T line2, linenr_T amount, linenr_T amount_after, _Bool adjust_folds, ExtmarkOp op);
static inline const fmark_T *next_buffer_mark(const buf_T *const buf, char *const mark_name) FUNC_ATTR_NONNULL_ALL FUNC_ATTR_WARN_UNUSED_RESULT;
static int add_mark(list_T *l, const char *mname, const pos_T *pos, int bufnr, const char *fname) FUNC_ATTR_NONNULL_ARG(1, 2, 3);
#include "nvim/func_attr.h"
