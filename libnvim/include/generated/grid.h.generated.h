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
DLLEXPORT void grid_adjust(ScreenGrid **grid, int *row_off, int *col_off);
DLLEXPORT int schar_from_cc(char *p, int c, int u8cc[6]);
DLLEXPORT void grid_clear_line(ScreenGrid *grid, size_t off, int width, _Bool valid);
DLLEXPORT void grid_invalidate(ScreenGrid *grid);
DLLEXPORT _Bool grid_invalid_row(ScreenGrid *grid, int row);
DLLEXPORT _Bool grid_lefthalve(ScreenGrid *grid, int row, int col);
DLLEXPORT int grid_fix_col(ScreenGrid *grid, int col, int row);
DLLEXPORT void grid_putchar(ScreenGrid *grid, int c, int row, int col, int attr);
DLLEXPORT void grid_getbytes(ScreenGrid *grid, int row, int col, char_u *bytes, int *attrp);
DLLEXPORT void grid_puts(ScreenGrid *grid, char *text, int row, int col, int attr);
DLLEXPORT void grid_puts_line_start(ScreenGrid *grid, int row);
DLLEXPORT void grid_put_schar(ScreenGrid *grid, int row, int col, char *schar, int attr);
DLLEXPORT void grid_puts_len(ScreenGrid *grid, char *text, int textlen, int row, int col, int attr);
DLLEXPORT void grid_puts_line_flush(_Bool set_cursor);
DLLEXPORT void grid_fill(ScreenGrid *grid, int start_row, int end_row, int start_col, int end_col, int c1, int c2, int attr);
DLLEXPORT void grid_put_linebuf(ScreenGrid *grid, int row, int coloff, int endcol, int clear_width, int rlflag, win_T *wp, int bg_attr, _Bool wrap);
DLLEXPORT void grid_alloc(ScreenGrid *grid, int rows, int columns, _Bool copy, _Bool valid);
DLLEXPORT void grid_free(ScreenGrid *grid);
DLLEXPORT void grid_free_all_mem(void);
DLLEXPORT void win_grid_alloc(win_T *wp);
DLLEXPORT void grid_assign_handle(ScreenGrid *grid);
DLLEXPORT void grid_ins_lines(ScreenGrid *grid, int row, int line_count, int end, int col, int width);
DLLEXPORT void grid_del_lines(ScreenGrid *grid, int row, int line_count, int end, int col, int width);
DLLEXPORT win_T *get_win_by_grid_handle(handle_T handle);
#include "nvim/func_attr.h"
