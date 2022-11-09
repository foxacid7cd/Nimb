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
DLLEXPORT void diff_buf_delete(buf_T *buf);
DLLEXPORT void diff_buf_adjust(win_T *win);
DLLEXPORT void diff_buf_add(buf_T *buf);
DLLEXPORT void diff_invalidate(buf_T *buf);
DLLEXPORT void diff_mark_adjust(linenr_T line1, linenr_T line2, linenr_T amount, linenr_T amount_after);
DLLEXPORT void diff_redraw(_Bool dofold);
DLLEXPORT int diff_internal(void) FUNC_ATTR_PURE;
DLLEXPORT void ex_diffupdate(exarg_T *eap);
DLLEXPORT void ex_diffpatch(exarg_T *eap);
DLLEXPORT void ex_diffsplit(exarg_T *eap);
DLLEXPORT void ex_diffthis(exarg_T *eap);
DLLEXPORT void diff_win_options(win_T *wp, int addbuf);
DLLEXPORT void ex_diffoff(exarg_T *eap);
DLLEXPORT void diff_clear(tabpage_T *tp) FUNC_ATTR_NONNULL_ALL;
DLLEXPORT _Bool diff_linematch(diff_T *dp);
DLLEXPORT int diff_check_with_linestatus(win_T *wp, linenr_T lnum, int *linestatus);
DLLEXPORT int diff_check(win_T *wp, linenr_T lnum);
DLLEXPORT void diff_set_topline(win_T *fromwin, win_T *towin);
DLLEXPORT int diffopt_changed(void);
DLLEXPORT _Bool diffopt_horizontal(void) FUNC_ATTR_PURE FUNC_ATTR_WARN_UNUSED_RESULT;
DLLEXPORT _Bool diffopt_hiddenoff(void) FUNC_ATTR_PURE;
DLLEXPORT _Bool diffopt_closeoff(void) FUNC_ATTR_PURE FUNC_ATTR_WARN_UNUSED_RESULT;
DLLEXPORT _Bool diffopt_filler(void) FUNC_ATTR_PURE FUNC_ATTR_WARN_UNUSED_RESULT;
DLLEXPORT _Bool diff_find_change(win_T *wp, linenr_T lnum, int *startp, int *endp) FUNC_ATTR_WARN_UNUSED_RESULT FUNC_ATTR_NONNULL_ALL;
DLLEXPORT _Bool diff_infold(win_T *wp, linenr_T lnum) FUNC_ATTR_PURE FUNC_ATTR_WARN_UNUSED_RESULT FUNC_ATTR_NONNULL_ARG(1);
DLLEXPORT void nv_diffgetput(_Bool put, size_t count);
DLLEXPORT void ex_diffgetput(exarg_T *eap);
DLLEXPORT _Bool diff_mode_buf(buf_T *buf) FUNC_ATTR_PURE FUNC_ATTR_WARN_UNUSED_RESULT FUNC_ATTR_NONNULL_ARG(1);
DLLEXPORT int diff_move_to(int dir, long count);
DLLEXPORT linenr_T diff_get_corresponding_line(buf_T *buf1, linenr_T lnum1);
DLLEXPORT linenr_T diff_lnum_win(linenr_T lnum, win_T *wp);
#include "nvim/func_attr.h"
