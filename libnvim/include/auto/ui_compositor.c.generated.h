#define DEFINE_FUNC_ATTRIBUTES
#include "nvim/func_attr.h"
#undef DEFINE_FUNC_ATTRIBUTES
static void ui_comp_raise_grid(ScreenGrid *grid, size_t new_index);
static void ui_comp_grid_cursor_goto(UI *ui, Integer grid_handle, Integer r, Integer c);
static void compose_line(Integer row, Integer startcol, Integer endcol, LineFlags flags);
static void compose_debug(Integer startrow, Integer endrow, Integer startcol, Integer endcol, int syn_id, _Bool delay);
static void debug_delay(Integer lines);
static void compose_area(Integer startrow, Integer endrow, Integer startcol, Integer endcol);
static void ui_comp_raw_line(UI *ui, Integer grid, Integer row, Integer startcol, Integer endcol, Integer clearcol, Integer clearattr, LineFlags flags, const schar_T *chunk, const sattr_T *attrs);
static void ui_comp_msg_set_pos(UI *ui, Integer grid, Integer row, Boolean scrolled, String sep_char);
static _Bool curgrid_covered_above(int row);
static void ui_comp_grid_scroll(UI *ui, Integer grid, Integer top, Integer bot, Integer left, Integer right, Integer rows, Integer cols);
static void ui_comp_grid_resize(UI *ui, Integer grid, Integer width, Integer height);
static void ui_comp_event(UI *ui, char *name, Array args);
static void ui_comp_update_ext(void);
#include "nvim/func_attr.h"
