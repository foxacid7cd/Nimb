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
DLLEXPORT void ui_init(void);
DLLEXPORT void ui_free_all_mem(void);
DLLEXPORT void ui_builtin_start(void);
DLLEXPORT _Bool ui_rgb_attached(void);
DLLEXPORT _Bool ui_override(void);
DLLEXPORT _Bool ui_active(void);
DLLEXPORT void ui_refresh(void);
DLLEXPORT int ui_pum_get_height(void);
DLLEXPORT _Bool ui_pum_get_pos(double *pwidth, double *pheight, double *prow, double *pcol);
DLLEXPORT void ui_schedule_refresh(void);
DLLEXPORT void ui_default_colors_set(void);
DLLEXPORT void ui_busy_start(void);
DLLEXPORT void ui_busy_stop(void);
DLLEXPORT void vim_beep(unsigned val);
DLLEXPORT void ui_attach_impl(UI *ui, uint64_t chanid);
DLLEXPORT void ui_detach_impl(UI *ui, uint64_t chanid);
DLLEXPORT void ui_set_ext_option(UI *ui, UIExtension ext, _Bool active);
DLLEXPORT void ui_line(ScreenGrid *grid, int row, int startcol, int endcol, int clearcol, int clearattr, _Bool wrap);
DLLEXPORT void ui_cursor_goto(int new_row, int new_col);
DLLEXPORT void ui_grid_cursor_goto(handle_T grid_handle, int new_row, int new_col);
DLLEXPORT void ui_check_cursor_grid(handle_T grid_handle);
DLLEXPORT void ui_mode_info_set(void);
DLLEXPORT int ui_current_row(void);
DLLEXPORT int ui_current_col(void);
DLLEXPORT handle_T ui_cursor_grid(void);
DLLEXPORT void ui_flush(void);
DLLEXPORT void ui_check_mouse(void);
DLLEXPORT void ui_cursor_shape(void);
DLLEXPORT _Bool ui_has(UIExtension ext);
DLLEXPORT Array ui_array(void);
DLLEXPORT void ui_grid_resize(handle_T grid_handle, int width, int height, Error *error);
#include "nvim/func_attr.h"
