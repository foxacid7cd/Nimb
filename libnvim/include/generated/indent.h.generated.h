#define DEFINE_FUNC_ATTRIBUTES
#include "nvim/func_attr.h"
#undef DEFINE_FUNC_ATTRIBUTES
#ifndef DLLEXPORT
#  ifdef MSWIN
#    define DLLEXPORT __declspec(dllexport)
#  else
#    define DLLEXPORT
#  endif
#endif
DLLEXPORT _Bool tabstop_set(char *var, long **array);
DLLEXPORT int tabstop_padding(colnr_T col, long ts_arg, const long *vts);
DLLEXPORT int tabstop_at(colnr_T col, long ts, const long *vts);
DLLEXPORT colnr_T tabstop_start(colnr_T col, long ts, long *vts);
DLLEXPORT void tabstop_fromto(colnr_T start_col, colnr_T end_col, long ts_arg, const long *vts, int *ntabs, int *nspcs);
DLLEXPORT _Bool tabstop_eq(const long *ts1, const long *ts2);
DLLEXPORT int *tabstop_copy(const long *oldts);
DLLEXPORT int tabstop_count(long *ts);
DLLEXPORT int tabstop_first(long *ts);
DLLEXPORT int get_sw_value(buf_T *buf);
DLLEXPORT long get_sw_value_pos(buf_T *buf, pos_T *pos);
DLLEXPORT long get_sw_value_indent(buf_T *buf);
DLLEXPORT long get_sw_value_col(buf_T *buf, colnr_T col);
DLLEXPORT int get_sts_value(void);
DLLEXPORT int get_indent(void);
DLLEXPORT int get_indent_lnum(linenr_T lnum);
DLLEXPORT int get_indent_buf(buf_T *buf, linenr_T lnum);
DLLEXPORT int get_indent_str(const char_u *ptr, int ts, _Bool list) FUNC_ATTR_NONNULL_ALL;
DLLEXPORT int get_indent_str_vtab(const char *ptr, long ts, long *vts, _Bool list);
DLLEXPORT int set_indent(int size, int flags);
DLLEXPORT int get_number_indent(linenr_T lnum);
DLLEXPORT _Bool briopt_check(win_T *wp);
DLLEXPORT int get_breakindent_win(win_T *wp, char_u *line) FUNC_ATTR_NONNULL_ALL;
DLLEXPORT int inindent(int extra);
DLLEXPORT _Bool may_do_si(void);
DLLEXPORT int get_expr_indent(void);
DLLEXPORT int get_lisp_indent(void);
DLLEXPORT void fixthisline(IndentGetter get_the_indent);
DLLEXPORT _Bool use_indentexpr_for_lisp(void);
DLLEXPORT void fix_indent(void);
#include "nvim/func_attr.h"
