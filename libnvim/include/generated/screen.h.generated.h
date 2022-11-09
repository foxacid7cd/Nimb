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
DLLEXPORT _Bool conceal_cursor_line(const win_T *wp) FUNC_ATTR_NONNULL_ALL;
DLLEXPORT _Bool win_cursorline_standout(const win_T *wp) FUNC_ATTR_NONNULL_ALL;
DLLEXPORT int win_signcol_width(win_T *wp);
DLLEXPORT void win_draw_end(win_T *wp, int c1, int c2, _Bool draw_margin, int row, int endrow, hlf_T hl);
DLLEXPORT int compute_foldcolumn(win_T *wp, int col);
DLLEXPORT size_t fill_foldcolumn(char_u *p, win_T *wp, foldinfo_T foldinfo, linenr_T lnum);
DLLEXPORT void rl_mirror(char *str);
DLLEXPORT void redraw_wildmenu(expand_T *xp, int num_matches, char **matches, int match, int showtail);
DLLEXPORT _Bool stl_connected(win_T *wp);
DLLEXPORT _Bool get_keymap_str(win_T *wp, char *fmt, char *buf, int len);
DLLEXPORT void start_search_hl(void);
DLLEXPORT void end_search_hl(void);
DLLEXPORT void check_for_delay(_Bool check_msg_scroll);
DLLEXPORT void stl_clear_click_defs(StlClickDefinition *const click_defs, const long click_defs_size);
DLLEXPORT StlClickDefinition *stl_alloc_click_defs(StlClickDefinition *cdp, long width, size_t *size);
DLLEXPORT void stl_fill_click_defs(StlClickDefinition *click_defs, StlClickRecord *click_recs, char *buf, int width, _Bool tabline);
DLLEXPORT void setcursor(void);
DLLEXPORT void setcursor_mayforce(_Bool force);
DLLEXPORT void win_scroll_lines(win_T *wp, int row, int line_count);
DLLEXPORT _Bool skip_showmode(void);
DLLEXPORT int showmode(void);
DLLEXPORT void unshowmode(_Bool force);
DLLEXPORT void clearmode(void);
DLLEXPORT void draw_tabline(void);
DLLEXPORT void get_trans_bufname(buf_T *buf);
DLLEXPORT int fillchar_vsep(win_T *wp, int *attr);
DLLEXPORT int fillchar_hsep(win_T *wp, int *attr);
DLLEXPORT _Bool redrawing(void);
DLLEXPORT _Bool messaging(void);
DLLEXPORT void comp_col(void);
DLLEXPORT int number_width(win_T *wp);
DLLEXPORT char *set_chars_option(win_T *wp, char **varp, _Bool apply);
DLLEXPORT char *check_chars_options(void);
DLLEXPORT void check_screensize(void);
#include "nvim/func_attr.h"
