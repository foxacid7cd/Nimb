#define DEFINE_FUNC_ATTRIBUTES
#include "nvim/func_attr.h"
#undef DEFINE_FUNC_ATTRIBUTES
static _Bool advance_color_col(int vcol, int **color_cols);
static void margin_columns_win(win_T *wp, int *left_col, int *right_col);
static int line_putchar(buf_T *buf, LineState *s, schar_T *dest, int maxcells, _Bool rl, int vcol);
static inline void provider_err_virt_text(linenr_T lnum, char *err);
static void draw_virt_text(win_T *wp, buf_T *buf, int col_off, int *end_col, int max_col, int win_row);
static int draw_virt_text_item(buf_T *buf, int col, VirtText vt, HlMode hl_mode, int max_col, int vcol);
static _Bool use_cursor_line_sign(win_T *wp, linenr_T lnum);
static void get_sign_display_info(_Bool nrcol, win_T *wp, linenr_T lnum, SignTextAttrs sattrs[], int row, int startrow, int filler_lines, int filler_todo, int *c_extrap, int *c_finalp, char_u *extra, size_t extra_size, char_u **pp_extra, int *n_extrap, int *char_attrp, int sign_idx, int cul_attr);
static int get_sign_attrs(buf_T *buf, linenr_T lnum, SignTextAttrs *sattrs, int *line_attr, int *num_attr, int *cul_attr);
static _Bool use_cursor_line_nr(win_T *wp, linenr_T lnum, int row, int startrow, int filler_lines);
static inline void get_line_number_str(win_T *wp, linenr_T lnum, char_u *buf, size_t buf_len);
static int get_line_number_attr(win_T *wp, linenr_T lnum, int row, int startrow, int filler_lines);
static void apply_cursorline_highlight(win_T *wp, linenr_T lnum, int *line_attr, int *cul_attr, int *line_attr_lowprio);
static _Bool check_mb_utf8(int *c, int *u8cc);
#include "nvim/func_attr.h"
