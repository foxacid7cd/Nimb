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
DLLEXPORT _Bool do_mouse(oparg_T *oap, int c, int dir, long count, _Bool fixindent);
DLLEXPORT _Bool is_mouse_key(int c);
DLLEXPORT void reset_dragwin(void);
DLLEXPORT int jump_to_mouse(int flags, _Bool *inclusive, int which_button);
DLLEXPORT _Bool mouse_comp_pos(win_T *win, int *rowp, int *colp, linenr_T *lnump);
DLLEXPORT win_T *mouse_find_win(int *gridp, int *rowp, int *colp);
DLLEXPORT colnr_T vcol2col(win_T *const wp, const linenr_T lnum, const colnr_T vcol) FUNC_ATTR_NONNULL_ALL FUNC_ATTR_WARN_UNUSED_RESULT;
DLLEXPORT void setmouse(void);
DLLEXPORT _Bool mouse_scroll_horiz(int dir);
DLLEXPORT int mouse_check_fold(void);
#include "nvim/func_attr.h"
