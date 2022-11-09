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
DLLEXPORT void ui_call_mode_info_set(Boolean enabled, Array cursor_styles);
DLLEXPORT void ui_call_update_menu(void);
DLLEXPORT void ui_call_busy_start(void);
DLLEXPORT void ui_call_busy_stop(void);
DLLEXPORT void ui_call_mouse_on(void);
DLLEXPORT void ui_call_mouse_off(void);
DLLEXPORT void ui_call_mode_change(String mode, Integer mode_idx);
DLLEXPORT void ui_call_bell(void);
DLLEXPORT void ui_call_visual_bell(void);
DLLEXPORT void ui_call_flush(void);
DLLEXPORT void ui_call_suspend(void);
DLLEXPORT void ui_call_set_title(String title);
DLLEXPORT void ui_call_set_icon(String icon);
DLLEXPORT void ui_call_screenshot(String path);
DLLEXPORT void ui_call_option_set(String name, Object value);
DLLEXPORT void ui_call_stop(void);
DLLEXPORT void ui_call_update_fg(Integer fg);
DLLEXPORT void ui_call_update_bg(Integer bg);
DLLEXPORT void ui_call_update_sp(Integer sp);
DLLEXPORT void ui_call_resize(Integer width, Integer height);
DLLEXPORT void ui_call_clear(void);
DLLEXPORT void ui_call_eol_clear(void);
DLLEXPORT void ui_call_cursor_goto(Integer row, Integer col);
DLLEXPORT void ui_call_put(String str);
DLLEXPORT void ui_call_set_scroll_region(Integer top, Integer bot, Integer left, Integer right);
DLLEXPORT void ui_call_scroll(Integer count);
DLLEXPORT void ui_call_default_colors_set(Integer rgb_fg, Integer rgb_bg, Integer rgb_sp, Integer cterm_fg, Integer cterm_bg);
DLLEXPORT void ui_call_hl_attr_define(Integer id, HlAttrs rgb_attrs, HlAttrs cterm_attrs, Array info);
DLLEXPORT void ui_call_hl_group_set(String name, Integer id);
DLLEXPORT void ui_call_grid_resize(Integer grid, Integer width, Integer height);
DLLEXPORT void ui_composed_call_grid_resize(Integer grid, Integer width, Integer height);
DLLEXPORT void ui_call_grid_clear(Integer grid);
DLLEXPORT void ui_call_grid_cursor_goto(Integer grid, Integer row, Integer col);
DLLEXPORT void ui_composed_call_grid_cursor_goto(Integer grid, Integer row, Integer col);
DLLEXPORT void ui_call_grid_line(Integer grid, Integer row, Integer col_start, Array data);
DLLEXPORT void ui_call_grid_scroll(Integer grid, Integer top, Integer bot, Integer left, Integer right, Integer rows, Integer cols);
DLLEXPORT void ui_composed_call_grid_scroll(Integer grid, Integer top, Integer bot, Integer left, Integer right, Integer rows, Integer cols);
DLLEXPORT void ui_call_grid_destroy(Integer grid);
DLLEXPORT void ui_call_raw_line(Integer grid, Integer row, Integer startcol, Integer endcol, Integer clearcol, Integer clearattr, LineFlags flags, const schar_T *chunk, const sattr_T *attrs);
DLLEXPORT void ui_composed_call_raw_line(Integer grid, Integer row, Integer startcol, Integer endcol, Integer clearcol, Integer clearattr, LineFlags flags, const schar_T *chunk, const sattr_T *attrs);
DLLEXPORT void ui_call_event(char *name, Array args);
DLLEXPORT void ui_composed_call_event(char *name, Array args);
DLLEXPORT void ui_call_win_pos(Integer grid, Window win, Integer startrow, Integer startcol, Integer width, Integer height);
DLLEXPORT void ui_call_win_float_pos(Integer grid, Window win, String anchor, Integer anchor_grid, Float anchor_row, Float anchor_col, Boolean focusable, Integer zindex);
DLLEXPORT void ui_call_win_external_pos(Integer grid, Window win);
DLLEXPORT void ui_call_win_hide(Integer grid);
DLLEXPORT void ui_call_win_close(Integer grid);
DLLEXPORT void ui_call_msg_set_pos(Integer grid, Integer row, Boolean scrolled, String sep_char);
DLLEXPORT void ui_composed_call_msg_set_pos(Integer grid, Integer row, Boolean scrolled, String sep_char);
DLLEXPORT void ui_call_win_viewport(Integer grid, Window win, Integer topline, Integer botline, Integer curline, Integer curcol, Integer line_count);
DLLEXPORT void ui_call_win_extmark(Integer grid, Window win, Integer ns_id, Integer mark_id, Integer row, Integer col);
DLLEXPORT void ui_call_popupmenu_show(Array items, Integer selected, Integer row, Integer col, Integer grid);
DLLEXPORT void ui_call_popupmenu_hide(void);
DLLEXPORT void ui_call_popupmenu_select(Integer selected);
DLLEXPORT void ui_call_tabline_update(Tabpage current, Array tabs, Buffer current_buffer, Array buffers);
DLLEXPORT void ui_call_cmdline_show(Array content, Integer pos, String firstc, String prompt, Integer indent, Integer level);
DLLEXPORT void ui_call_cmdline_pos(Integer pos, Integer level);
DLLEXPORT void ui_call_cmdline_special_char(String c, Boolean shift, Integer level);
DLLEXPORT void ui_call_cmdline_hide(Integer level);
DLLEXPORT void ui_call_cmdline_block_show(Array lines);
DLLEXPORT void ui_call_cmdline_block_append(Array lines);
DLLEXPORT void ui_call_cmdline_block_hide(void);
DLLEXPORT void ui_call_wildmenu_show(Array items);
DLLEXPORT void ui_call_wildmenu_select(Integer selected);
DLLEXPORT void ui_call_wildmenu_hide(void);
DLLEXPORT void ui_call_msg_show(String kind, Array content, Boolean replace_last);
DLLEXPORT void ui_call_msg_clear(void);
DLLEXPORT void ui_call_msg_showcmd(Array content);
DLLEXPORT void ui_call_msg_showmode(Array content);
DLLEXPORT void ui_call_msg_ruler(Array content);
DLLEXPORT void ui_call_msg_history_show(Array entries);
DLLEXPORT void ui_call_msg_history_clear(void);
#include "nvim/func_attr.h"
