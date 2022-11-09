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
DLLEXPORT void redraw_for_cursorline(win_T *wp) FUNC_ATTR_NONNULL_ALL;
DLLEXPORT void update_topline(win_T *wp);
DLLEXPORT void update_topline_win(win_T *win);
DLLEXPORT void update_curswant(void);
DLLEXPORT void check_cursor_moved(win_T *wp);
DLLEXPORT void changed_window_setting(void);
DLLEXPORT void changed_window_setting_win(win_T *wp);
DLLEXPORT void set_topline(win_T *wp, linenr_T lnum);
DLLEXPORT void changed_cline_bef_curs(void);
DLLEXPORT void changed_cline_bef_curs_win(win_T *wp);
DLLEXPORT void changed_line_abv_curs(void);
DLLEXPORT void changed_line_abv_curs_win(win_T *wp);
DLLEXPORT void validate_botline(win_T *wp);
DLLEXPORT void invalidate_botline(void);
DLLEXPORT void invalidate_botline_win(win_T *wp);
DLLEXPORT void approximate_botline_win(win_T *wp);
DLLEXPORT int cursor_valid(void);
DLLEXPORT void validate_cursor(void);
DLLEXPORT void validate_virtcol(void);
DLLEXPORT void validate_virtcol_win(win_T *wp);
DLLEXPORT void validate_cheight(void);
DLLEXPORT void validate_cursor_col(void);
DLLEXPORT int win_col_off(win_T *wp);
DLLEXPORT int curwin_col_off(void);
DLLEXPORT int win_col_off2(win_T *wp);
DLLEXPORT int curwin_col_off2(void);
DLLEXPORT void curs_columns(win_T *wp, int may_scroll);
DLLEXPORT void textpos2screenpos(win_T *wp, pos_T *pos, int *rowp, int *scolp, int *ccolp, int *ecolp, _Bool local);
DLLEXPORT void f_screenpos(typval_T *argvars, typval_T *rettv, EvalFuncData fptr);
DLLEXPORT void f_virtcol2col(typval_T *argvars, typval_T *rettv, EvalFuncData fptr);
DLLEXPORT _Bool scrolldown(long line_count, int byfold);
DLLEXPORT _Bool scrollup(long line_count, int byfold);
DLLEXPORT void check_topfill(win_T *wp, _Bool down);
DLLEXPORT void scrolldown_clamp(void);
DLLEXPORT void scrollup_clamp(void);
DLLEXPORT void scroll_cursor_top(int min_scroll, int always);
DLLEXPORT void set_empty_rows(win_T *wp, int used);
DLLEXPORT void scroll_cursor_bot(int min_scroll, int set_topbot);
DLLEXPORT void scroll_cursor_halfway(int atend);
DLLEXPORT void cursor_correct(void);
DLLEXPORT int onepage(Direction dir, long count);
DLLEXPORT void halfpage(_Bool flag, linenr_T Prenum);
DLLEXPORT void do_check_cursorbind(void);
#include "nvim/func_attr.h"
