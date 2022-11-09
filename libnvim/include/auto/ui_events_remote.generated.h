static void remote_ui_mode_info_set(UI *ui, Boolean enabled, Array cursor_styles)
{
  UIData *data = ui->data;
  Array args = data->call_buf;
  ADD_C(args, BOOLEAN_OBJ(enabled));
  ADD_C(args, ARRAY_OBJ(cursor_styles));
  push_call(ui, "mode_info_set", args);
}

static void remote_ui_update_menu(UI *ui)
{
  UIData *data = ui->data;
  Array args = data->call_buf;
  push_call(ui, "update_menu", args);
}

static void remote_ui_busy_start(UI *ui)
{
  UIData *data = ui->data;
  Array args = data->call_buf;
  push_call(ui, "busy_start", args);
}

static void remote_ui_busy_stop(UI *ui)
{
  UIData *data = ui->data;
  Array args = data->call_buf;
  push_call(ui, "busy_stop", args);
}

static void remote_ui_mouse_on(UI *ui)
{
  UIData *data = ui->data;
  Array args = data->call_buf;
  push_call(ui, "mouse_on", args);
}

static void remote_ui_mouse_off(UI *ui)
{
  UIData *data = ui->data;
  Array args = data->call_buf;
  push_call(ui, "mouse_off", args);
}

static void remote_ui_mode_change(UI *ui, String mode, Integer mode_idx)
{
  UIData *data = ui->data;
  Array args = data->call_buf;
  ADD_C(args, STRING_OBJ(mode));
  ADD_C(args, INTEGER_OBJ(mode_idx));
  push_call(ui, "mode_change", args);
}

static void remote_ui_bell(UI *ui)
{
  UIData *data = ui->data;
  Array args = data->call_buf;
  push_call(ui, "bell", args);
}

static void remote_ui_visual_bell(UI *ui)
{
  UIData *data = ui->data;
  Array args = data->call_buf;
  push_call(ui, "visual_bell", args);
}

static void remote_ui_suspend(UI *ui)
{
  UIData *data = ui->data;
  Array args = data->call_buf;
  push_call(ui, "suspend", args);
}

static void remote_ui_set_title(UI *ui, String title)
{
  UIData *data = ui->data;
  Array args = data->call_buf;
  ADD_C(args, STRING_OBJ(title));
  push_call(ui, "set_title", args);
}

static void remote_ui_set_icon(UI *ui, String icon)
{
  UIData *data = ui->data;
  Array args = data->call_buf;
  ADD_C(args, STRING_OBJ(icon));
  push_call(ui, "set_icon", args);
}

static void remote_ui_option_set(UI *ui, String name, Object value)
{
  UIData *data = ui->data;
  Array args = data->call_buf;
  ADD_C(args, STRING_OBJ(name));
  ADD_C(args, OBJECT_OBJ(value));
  push_call(ui, "option_set", args);
}

static void remote_ui_hl_group_set(UI *ui, String name, Integer id)
{
  UIData *data = ui->data;
  Array args = data->call_buf;
  ADD_C(args, STRING_OBJ(name));
  ADD_C(args, INTEGER_OBJ(id));
  push_call(ui, "hl_group_set", args);
}

static void remote_ui_msg_set_pos(UI *ui, Integer grid, Integer row, Boolean scrolled, String sep_char)
{
  UIData *data = ui->data;
  Array args = data->call_buf;
  ADD_C(args, INTEGER_OBJ(grid));
  ADD_C(args, INTEGER_OBJ(row));
  ADD_C(args, BOOLEAN_OBJ(scrolled));
  ADD_C(args, STRING_OBJ(sep_char));
  push_call(ui, "msg_set_pos", args);
}

static void remote_ui_win_viewport(UI *ui, Integer grid, Window win, Integer topline, Integer botline, Integer curline, Integer curcol, Integer line_count)
{
  UIData *data = ui->data;
  Array args = data->call_buf;
  ADD_C(args, INTEGER_OBJ(grid));
  ADD_C(args, WINDOW_OBJ(win));
  ADD_C(args, INTEGER_OBJ(topline));
  ADD_C(args, INTEGER_OBJ(botline));
  ADD_C(args, INTEGER_OBJ(curline));
  ADD_C(args, INTEGER_OBJ(curcol));
  ADD_C(args, INTEGER_OBJ(line_count));
  push_call(ui, "win_viewport", args);
}

