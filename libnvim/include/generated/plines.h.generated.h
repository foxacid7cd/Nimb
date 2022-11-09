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
DLLEXPORT int plines_win(win_T *wp, linenr_T lnum, _Bool winheight);
DLLEXPORT int win_get_fill(win_T *wp, linenr_T lnum);
DLLEXPORT _Bool win_may_fill(win_T *wp);
DLLEXPORT int plines_win_nofill(win_T *wp, linenr_T lnum, _Bool winheight);
DLLEXPORT int plines_win_nofold(win_T *wp, linenr_T lnum);
DLLEXPORT int plines_win_col(win_T *wp, linenr_T lnum, long column);
DLLEXPORT int plines_win_full(win_T *wp, linenr_T lnum, linenr_T *const nextp, _Bool *const foldedp, const _Bool cache);
DLLEXPORT int plines_m_win(win_T *wp, linenr_T first, linenr_T last);
DLLEXPORT int win_chartabsize(win_T *wp, char *p, colnr_T col);
DLLEXPORT int linetabsize(char_u *s);
DLLEXPORT int linetabsize_col(int startcol, char *s);
DLLEXPORT unsigned int win_linetabsize(win_T *wp, linenr_T lnum, char_u *line, colnr_T len);
DLLEXPORT void init_chartabsize_arg(chartabsize_T *cts, win_T *wp, linenr_T lnum FUNC_ATTR_UNUSED, colnr_T col, char *line, char *ptr);
DLLEXPORT void clear_chartabsize_arg(chartabsize_T *cts);
DLLEXPORT int lbr_chartabsize(chartabsize_T *cts);
DLLEXPORT int lbr_chartabsize_adv(chartabsize_T *cts);
DLLEXPORT int win_lbr_chartabsize(chartabsize_T *cts, int *headp);
#include "nvim/func_attr.h"
