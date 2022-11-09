# 1 "/Users/foxacid/ghq/github.com/foxacid7cd/Nims/Targets/libNims/build/src/nvim/auto/ui_events_call.generated.h"
# 1 "<built-in>" 1
# 1 "<built-in>" 3
# 400 "<built-in>" 3
# 1 "<command line>" 1
# 1 "<built-in>" 2
# 1 "/Users/foxacid/ghq/github.com/foxacid7cd/Nims/Targets/libNims/build/src/nvim/auto/ui_events_call.generated.h" 2
void ui_call_mode_info_set(Boolean enabled, Array cursor_styles)
{
  UI_CALL(true, mode_info_set, ui, enabled, cursor_styles);
}

void ui_call_update_menu(void)
{
  UI_CALL(true, update_menu, ui);
}

void ui_call_busy_start(void)
{
  UI_CALL(true, busy_start, ui);
}

void ui_call_busy_stop(void)
{
  UI_CALL(true, busy_stop, ui);
}

void ui_call_mouse_on(void)
{
  UI_CALL(true, mouse_on, ui);
}

void ui_call_mouse_off(void)
{
  UI_CALL(true, mouse_off, ui);
}

void ui_call_mode_change(String mode, Integer mode_idx)
{
  UI_CALL(true, mode_change, ui, mode, mode_idx);
}

void ui_call_bell(void)
{
  UI_CALL(true, bell, ui);
}

void ui_call_visual_bell(void)
{
  UI_CALL(true, visual_bell, ui);
}

void ui_call_flush(void)
{
  UI_CALL(true, flush, ui);
}

void ui_call_suspend(void)
{
  UI_CALL(true, suspend, ui);
}

void ui_call_set_title(String title)
{
  UI_CALL(true, set_title, ui, title);
}

void ui_call_set_icon(String icon)
{
  UI_CALL(true, set_icon, ui, icon);
}

void ui_call_screenshot(String path)
{
  UI_CALL(true, screenshot, ui, path);
}

void ui_call_option_set(String name, Object value)
{
  UI_CALL(true, option_set, ui, name, value);
}

void ui_call_stop(void)
{
  UI_CALL(true, stop, ui);
}

void ui_call_update_fg(Integer fg)
{
  Array args = call_buf;
  ADD_C(args, INTEGER_OBJ(fg));
  UI_LOG(update_fg);
  ui_call_event("update_fg", args);
}

void ui_call_update_bg(Integer bg)
{
  Array args = call_buf;
  ADD_C(args, INTEGER_OBJ(bg));
  UI_LOG(update_bg);
  ui_call_event("update_bg", args);
}

void ui_call_update_sp(Integer sp)
{
  Array args = call_buf;
  ADD_C(args, INTEGER_OBJ(sp));
  UI_LOG(update_sp);
  ui_call_event("update_sp", args);
}

void ui_call_resize(Integer width, Integer height)
{
  Array args = call_buf;
  ADD_C(args, INTEGER_OBJ(width));
  ADD_C(args, INTEGER_OBJ(height));
  UI_LOG(resize);
  ui_call_event("resize", args);
}

void ui_call_clear(void)
{
  Array args = call_buf;
  UI_LOG(clear);
  ui_call_event("clear", args);
}

void ui_call_eol_clear(void)
{
  Array args = call_buf;
  UI_LOG(eol_clear);
  ui_call_event("eol_clear", args);
}

void ui_call_cursor_goto(Integer row, Integer col)
{
  Array args = call_buf;
  ADD_C(args, INTEGER_OBJ(row));
  ADD_C(args, INTEGER_OBJ(col));
  UI_LOG(cursor_goto);
  ui_call_event("cursor_goto", args);
}

void ui_call_put(String str)
{
  Array args = call_buf;
  ADD_C(args, STRING_OBJ(str));
  UI_LOG(put);
  ui_call_event("put", args);
}

void ui_call_set_scroll_region(Integer top, Integer bot, Integer left, Integer right)
{
  Array args = call_buf;
  ADD_C(args, INTEGER_OBJ(top));
  ADD_C(args, INTEGER_OBJ(bot));
  ADD_C(args, INTEGER_OBJ(left));
  ADD_C(args, INTEGER_OBJ(right));
  UI_LOG(set_scroll_region);
  ui_call_event("set_scroll_region", args);
}

void ui_call_scroll(Integer count)
{
  Array args = call_buf;
  ADD_C(args, INTEGER_OBJ(count));
  UI_LOG(scroll);
  ui_call_event("scroll", args);
}

void ui_call_default_colors_set(Integer rgb_fg, Integer rgb_bg, Integer rgb_sp, Integer cterm_fg, Integer cterm_bg)
{
  UI_CALL(true, default_colors_set, ui, rgb_fg, rgb_bg, rgb_sp, cterm_fg, cterm_bg);
}

void ui_call_hl_attr_define(Integer id, HlAttrs rgb_attrs, HlAttrs cterm_attrs, Array info)
{
  UI_CALL(true, hl_attr_define, ui, id, rgb_attrs, cterm_attrs, info);
}

void ui_call_hl_group_set(String name, Integer id)
{
  UI_CALL(true, hl_group_set, ui, name, id);
}

void ui_call_grid_resize(Integer grid, Integer width, Integer height)
{
  UI_CALL(!ui->composed, grid_resize, ui, grid, width, height);
}

void ui_composed_call_grid_resize(Integer grid, Integer width, Integer height)
{
  UI_CALL(ui->composed, grid_resize, ui, grid, width, height);
}

void ui_call_grid_clear(Integer grid)
{
  UI_CALL(true, grid_clear, ui, grid);
}

void ui_call_grid_cursor_goto(Integer grid, Integer row, Integer col)
{
  UI_CALL(!ui->composed, grid_cursor_goto, ui, grid, row, col);
}

void ui_composed_call_grid_cursor_goto(Integer grid, Integer row, Integer col)
{
  UI_CALL(ui->composed, grid_cursor_goto, ui, grid, row, col);
}

void ui_call_grid_line(Integer grid, Integer row, Integer col_start, Array data)
{
  Array args = call_buf;
  ADD_C(args, INTEGER_OBJ(grid));
  ADD_C(args, INTEGER_OBJ(row));
  ADD_C(args, INTEGER_OBJ(col_start));
  ADD_C(args, ARRAY_OBJ(data));
  UI_LOG(grid_line);
  ui_call_event("grid_line", args);
}

void ui_call_grid_scroll(Integer grid, Integer top, Integer bot, Integer left, Integer right, Integer rows, Integer cols)
{
  UI_CALL(!ui->composed, grid_scroll, ui, grid, top, bot, left, right, rows, cols);
}

void ui_composed_call_grid_scroll(Integer grid, Integer top, Integer bot, Integer left, Integer right, Integer rows, Integer cols)
{
  UI_CALL(ui->composed, grid_scroll, ui, grid, top, bot, left, right, rows, cols);
}

void ui_call_grid_destroy(Integer grid)
{
  Array args = call_buf;
  ADD_C(args, INTEGER_OBJ(grid));
  UI_LOG(grid_destroy);
  ui_call_event("grid_destroy", args);
}

void ui_call_raw_line(Integer grid, Integer row, Integer startcol, Integer endcol, Integer clearcol, Integer clearattr, LineFlags flags, const schar_T * chunk, const sattr_T * attrs)
{
  UI_CALL(!ui->composed, raw_line, ui, grid, row, startcol, endcol, clearcol, clearattr, flags, chunk, attrs);
}

void ui_composed_call_raw_line(Integer grid, Integer row, Integer startcol, Integer endcol, Integer clearcol, Integer clearattr, LineFlags flags, const schar_T * chunk, const sattr_T * attrs)
{
  UI_CALL(ui->composed, raw_line, ui, grid, row, startcol, endcol, clearcol, clearattr, flags, chunk, attrs);
}

void ui_call_event(char * name, Array args)
{
  UI_CALL(!ui->composed, event, ui, name, args);
}

void ui_composed_call_event(char * name, Array args)
{
  UI_CALL(ui->composed, event, ui, name, args);
}

void ui_call_win_pos(Integer grid, Window win, Integer startrow, Integer startcol, Integer width, Integer height)
{
  Array args = call_buf;
  ADD_C(args, INTEGER_OBJ(grid));
  ADD_C(args, WINDOW_OBJ(win));
  ADD_C(args, INTEGER_OBJ(startrow));
  ADD_C(args, INTEGER_OBJ(startcol));
  ADD_C(args, INTEGER_OBJ(width));
  ADD_C(args, INTEGER_OBJ(height));
  UI_LOG(win_pos);
  ui_call_event("win_pos", args);
}

void ui_call_win_float_pos(Integer grid, Window win, String anchor, Integer anchor_grid, Float anchor_row, Float anchor_col, Boolean focusable, Integer zindex)
{
  Array args = call_buf;
  ADD_C(args, INTEGER_OBJ(grid));
  ADD_C(args, WINDOW_OBJ(win));
  ADD_C(args, STRING_OBJ(anchor));
  ADD_C(args, INTEGER_OBJ(anchor_grid));
  ADD_C(args, FLOAT_OBJ(anchor_row));
  ADD_C(args, FLOAT_OBJ(anchor_col));
  ADD_C(args, BOOLEAN_OBJ(focusable));
  ADD_C(args, INTEGER_OBJ(zindex));
  UI_LOG(win_float_pos);
  ui_call_event("win_float_pos", args);
}

void ui_call_win_external_pos(Integer grid, Window win)
{
  Array args = call_buf;
  ADD_C(args, INTEGER_OBJ(grid));
  ADD_C(args, WINDOW_OBJ(win));
  UI_LOG(win_external_pos);
  ui_call_event("win_external_pos", args);
}

void ui_call_win_hide(Integer grid)
{
  Array args = call_buf;
  ADD_C(args, INTEGER_OBJ(grid));
  UI_LOG(win_hide);
  ui_call_event("win_hide", args);
}

void ui_call_win_close(Integer grid)
{
  Array args = call_buf;
  ADD_C(args, INTEGER_OBJ(grid));
  UI_LOG(win_close);
  ui_call_event("win_close", args);
}

void ui_call_msg_set_pos(Integer grid, Integer row, Boolean scrolled, String sep_char)
{
  UI_CALL(!ui->composed, msg_set_pos, ui, grid, row, scrolled, sep_char);
}

void ui_composed_call_msg_set_pos(Integer grid, Integer row, Boolean scrolled, String sep_char)
{
  UI_CALL(ui->composed, msg_set_pos, ui, grid, row, scrolled, sep_char);
}

void ui_call_win_viewport(Integer grid, Window win, Integer topline, Integer botline, Integer curline, Integer curcol, Integer line_count)
{
  UI_CALL(true, win_viewport, ui, grid, win, topline, botline, curline, curcol, line_count);
}

void ui_call_win_extmark(Integer grid, Window win, Integer ns_id, Integer mark_id, Integer row, Integer col)
{
  Array args = call_buf;
  ADD_C(args, INTEGER_OBJ(grid));
  ADD_C(args, WINDOW_OBJ(win));
  ADD_C(args, INTEGER_OBJ(ns_id));
  ADD_C(args, INTEGER_OBJ(mark_id));
  ADD_C(args, INTEGER_OBJ(row));
  ADD_C(args, INTEGER_OBJ(col));
  UI_LOG(win_extmark);
  ui_call_event("win_extmark", args);
}

void ui_call_popupmenu_show(Array items, Integer selected, Integer row, Integer col, Integer grid)
{
  Array args = call_buf;
  ADD_C(args, ARRAY_OBJ(items));
  ADD_C(args, INTEGER_OBJ(selected));
  ADD_C(args, INTEGER_OBJ(row));
  ADD_C(args, INTEGER_OBJ(col));
  ADD_C(args, INTEGER_OBJ(grid));
  UI_LOG(popupmenu_show);
  ui_call_event("popupmenu_show", args);
}

void ui_call_popupmenu_hide(void)
{
  Array args = call_buf;
  UI_LOG(popupmenu_hide);
  ui_call_event("popupmenu_hide", args);
}

void ui_call_popupmenu_select(Integer selected)
{
  Array args = call_buf;
  ADD_C(args, INTEGER_OBJ(selected));
  UI_LOG(popupmenu_select);
  ui_call_event("popupmenu_select", args);
}

void ui_call_tabline_update(Tabpage current, Array tabs, Buffer current_buffer, Array buffers)
{
  Array args = call_buf;
  ADD_C(args, TABPAGE_OBJ(current));
  ADD_C(args, ARRAY_OBJ(tabs));
  ADD_C(args, BUFFER_OBJ(current_buffer));
  ADD_C(args, ARRAY_OBJ(buffers));
  UI_LOG(tabline_update);
  ui_call_event("tabline_update", args);
}

void ui_call_cmdline_show(Array content, Integer pos, String firstc, String prompt, Integer indent, Integer level)
{
  Array args = call_buf;
  ADD_C(args, ARRAY_OBJ(content));
  ADD_C(args, INTEGER_OBJ(pos));
  ADD_C(args, STRING_OBJ(firstc));
  ADD_C(args, STRING_OBJ(prompt));
  ADD_C(args, INTEGER_OBJ(indent));
  ADD_C(args, INTEGER_OBJ(level));
  UI_LOG(cmdline_show);
  ui_call_event("cmdline_show", args);
}

void ui_call_cmdline_pos(Integer pos, Integer level)
{
  Array args = call_buf;
  ADD_C(args, INTEGER_OBJ(pos));
  ADD_C(args, INTEGER_OBJ(level));
  UI_LOG(cmdline_pos);
  ui_call_event("cmdline_pos", args);
}

void ui_call_cmdline_special_char(String c, Boolean shift, Integer level)
{
  Array args = call_buf;
  ADD_C(args, STRING_OBJ(c));
  ADD_C(args, BOOLEAN_OBJ(shift));
  ADD_C(args, INTEGER_OBJ(level));
  UI_LOG(cmdline_special_char);
  ui_call_event("cmdline_special_char", args);
}

void ui_call_cmdline_hide(Integer level)
{
  Array args = call_buf;
  ADD_C(args, INTEGER_OBJ(level));
  UI_LOG(cmdline_hide);
  ui_call_event("cmdline_hide", args);
}

void ui_call_cmdline_block_show(Array lines)
{
  Array args = call_buf;
  ADD_C(args, ARRAY_OBJ(lines));
  UI_LOG(cmdline_block_show);
  ui_call_event("cmdline_block_show", args);
}

void ui_call_cmdline_block_append(Array lines)
{
  Array args = call_buf;
  ADD_C(args, ARRAY_OBJ(lines));
  UI_LOG(cmdline_block_append);
  ui_call_event("cmdline_block_append", args);
}

void ui_call_cmdline_block_hide(void)
{
  Array args = call_buf;
  UI_LOG(cmdline_block_hide);
  ui_call_event("cmdline_block_hide", args);
}

void ui_call_wildmenu_show(Array items)
{
  UI_CALL(true, wildmenu_show, ui, items);
}

void ui_call_wildmenu_select(Integer selected)
{
  UI_CALL(true, wildmenu_select, ui, selected);
}

void ui_call_wildmenu_hide(void)
{
  UI_CALL(true, wildmenu_hide, ui);
}

void ui_call_msg_show(String kind, Array content, Boolean replace_last)
{
  Array args = call_buf;
  ADD_C(args, STRING_OBJ(kind));
  ADD_C(args, ARRAY_OBJ(content));
  ADD_C(args, BOOLEAN_OBJ(replace_last));
  UI_LOG(msg_show);
  ui_call_event("msg_show", args);
}

void ui_call_msg_clear(void)
{
  Array args = call_buf;
  UI_LOG(msg_clear);
  ui_call_event("msg_clear", args);
}

void ui_call_msg_showcmd(Array content)
{
  Array args = call_buf;
  ADD_C(args, ARRAY_OBJ(content));
  UI_LOG(msg_showcmd);
  ui_call_event("msg_showcmd", args);
}

void ui_call_msg_showmode(Array content)
{
  Array args = call_buf;
  ADD_C(args, ARRAY_OBJ(content));
  UI_LOG(msg_showmode);
  ui_call_event("msg_showmode", args);
}

void ui_call_msg_ruler(Array content)
{
  Array args = call_buf;
  ADD_C(args, ARRAY_OBJ(content));
  UI_LOG(msg_ruler);
  ui_call_event("msg_ruler", args);
}

void ui_call_msg_history_show(Array entries)
{
  Array args = call_buf;
  ADD_C(args, ARRAY_OBJ(entries));
  UI_LOG(msg_history_show);
  ui_call_event("msg_history_show", args);
}

void ui_call_msg_history_clear(void)
{
  Array args = call_buf;
  UI_LOG(msg_history_clear);
  ui_call_event("msg_history_clear", args);
}
