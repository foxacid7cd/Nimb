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
DLLEXPORT int getviscol(void);
DLLEXPORT int getviscol2(colnr_T col, colnr_T coladd);
DLLEXPORT int coladvance_force(colnr_T wcol);
DLLEXPORT int coladvance(colnr_T wcol);
DLLEXPORT int getvpos(pos_T *pos, colnr_T wcol);
DLLEXPORT int inc_cursor(void);
DLLEXPORT int dec_cursor(void);
DLLEXPORT linenr_T get_cursor_rel_lnum(win_T *wp, linenr_T lnum);
DLLEXPORT void check_pos(buf_T *buf, pos_T *pos);
DLLEXPORT void check_cursor_lnum(void);
DLLEXPORT void check_cursor_col(void);
DLLEXPORT void check_cursor_col_win(win_T *win);
DLLEXPORT void check_cursor(void);
DLLEXPORT void check_visual_pos(void);
DLLEXPORT void adjust_cursor_col(void);
DLLEXPORT _Bool leftcol_changed(void);
DLLEXPORT int gchar_cursor(void);
DLLEXPORT void pchar_cursor(char_u c);
DLLEXPORT char *get_cursor_line_ptr(void);
DLLEXPORT char *get_cursor_pos_ptr(void);
#include "nvim/func_attr.h"
