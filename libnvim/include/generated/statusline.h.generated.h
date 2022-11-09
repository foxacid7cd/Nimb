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
DLLEXPORT void win_redr_status(win_T *wp);
DLLEXPORT void win_redr_winbar(win_T *wp);
DLLEXPORT void win_redr_ruler(win_T *wp, _Bool always);
DLLEXPORT int fillchar_status(int *attr, win_T *wp);
DLLEXPORT void redraw_custom_statusline(win_T *wp);
DLLEXPORT void win_redr_custom(win_T *wp, _Bool draw_winbar, _Bool draw_ruler);
DLLEXPORT int build_stl_str_hl(win_T *wp, char *out, size_t outlen, char *fmt, char *opt_name, int opt_scope, int fillchar, int maxwidth, stl_hlrec_t **hltab, StlClickRecord **tabtab);
#include "nvim/func_attr.h"
