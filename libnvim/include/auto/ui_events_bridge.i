# 1 "/Users/foxacid/ghq/github.com/foxacid7cd/Nims/Targets/libNims/build/src/nvim/auto/ui_events_bridge.generated.h"
# 1 "<built-in>" 1
# 1 "<built-in>" 3
# 400 "<built-in>" 3
# 1 "<command line>" 1
# 1 "<built-in>" 2
# 1 "/Users/foxacid/ghq/github.com/foxacid7cd/Nims/Targets/libNims/build/src/nvim/auto/ui_events_bridge.generated.h" 2
static void ui_bridge_mode_info_set_event(void **argv)
{
  UI *ui = UI(argv[0]);
  Array cursor_styles = (Array){.items = argv[2],.size = (size_t)argv[3]};
  ui->mode_info_set(ui, PTR2INT(argv[1]), cursor_styles);
  api_free_array(cursor_styles);
}

static void ui_bridge_mode_info_set(UI *ui, Boolean enabled, Array cursor_styles)
{
  Array copy_cursor_styles = copy_array(cursor_styles, NULL);
  UI_BRIDGE_CALL(ui, mode_info_set, 4, ui, INT2PTR(enabled), copy_cursor_styles.items, INT2PTR(copy_cursor_styles.size));
}

static void ui_bridge_update_menu_event(void **argv)
{
  UI *ui = UI(argv[0]);
  ui->update_menu(ui);
}

static void ui_bridge_update_menu(UI *ui)
{
  UI_BRIDGE_CALL(ui, update_menu, 1, ui);
}

static void ui_bridge_busy_start_event(void **argv)
{
  UI *ui = UI(argv[0]);
  ui->busy_start(ui);
}

static void ui_bridge_busy_start(UI *ui)
{
  UI_BRIDGE_CALL(ui, busy_start, 1, ui);
}

static void ui_bridge_busy_stop_event(void **argv)
{
  UI *ui = UI(argv[0]);
  ui->busy_stop(ui);
}

static void ui_bridge_busy_stop(UI *ui)
{
  UI_BRIDGE_CALL(ui, busy_stop, 1, ui);
}

static void ui_bridge_mouse_on_event(void **argv)
{
  UI *ui = UI(argv[0]);
  ui->mouse_on(ui);
}

static void ui_bridge_mouse_on(UI *ui)
{
  UI_BRIDGE_CALL(ui, mouse_on, 1, ui);
}

static void ui_bridge_mouse_off_event(void **argv)
{
  UI *ui = UI(argv[0]);
  ui->mouse_off(ui);
}

static void ui_bridge_mouse_off(UI *ui)
{
  UI_BRIDGE_CALL(ui, mouse_off, 1, ui);
}

static void ui_bridge_mode_change_event(void **argv)
{
  UI *ui = UI(argv[0]);
  String mode = (String){.data = argv[1],.size = (size_t)argv[2]};
  ui->mode_change(ui, mode, PTR2INT(argv[3]));
  api_free_string(mode);
}

static void ui_bridge_mode_change(UI *ui, String mode, Integer mode_idx)
{
  String copy_mode = copy_string(mode, NULL);
  UI_BRIDGE_CALL(ui, mode_change, 4, ui, copy_mode.data, INT2PTR(copy_mode.size), INT2PTR(mode_idx));
}

static void ui_bridge_bell_event(void **argv)
{
  UI *ui = UI(argv[0]);
  ui->bell(ui);
}

static void ui_bridge_bell(UI *ui)
{
  UI_BRIDGE_CALL(ui, bell, 1, ui);
}

static void ui_bridge_visual_bell_event(void **argv)
{
  UI *ui = UI(argv[0]);
  ui->visual_bell(ui);
}

static void ui_bridge_visual_bell(UI *ui)
{
  UI_BRIDGE_CALL(ui, visual_bell, 1, ui);
}

static void ui_bridge_flush_event(void **argv)
{
  UI *ui = UI(argv[0]);
  ui->flush(ui);
}

static void ui_bridge_flush(UI *ui)
{
  UI_BRIDGE_CALL(ui, flush, 1, ui);
}

static void ui_bridge_set_title_event(void **argv)
{
  UI *ui = UI(argv[0]);
  String title = (String){.data = argv[1],.size = (size_t)argv[2]};
  ui->set_title(ui, title);
  api_free_string(title);
}

static void ui_bridge_set_title(UI *ui, String title)
{
  String copy_title = copy_string(title, NULL);
  UI_BRIDGE_CALL(ui, set_title, 3, ui, copy_title.data, INT2PTR(copy_title.size));
}

static void ui_bridge_set_icon_event(void **argv)
{
  UI *ui = UI(argv[0]);
  String icon = (String){.data = argv[1],.size = (size_t)argv[2]};
  ui->set_icon(ui, icon);
  api_free_string(icon);
}

static void ui_bridge_set_icon(UI *ui, String icon)
{
  String copy_icon = copy_string(icon, NULL);
  UI_BRIDGE_CALL(ui, set_icon, 3, ui, copy_icon.data, INT2PTR(copy_icon.size));
}

static void ui_bridge_screenshot_event(void **argv)
{
  UI *ui = UI(argv[0]);
  String path = (String){.data = argv[1],.size = (size_t)argv[2]};
  ui->screenshot(ui, path);
  api_free_string(path);
}

static void ui_bridge_screenshot(UI *ui, String path)
{
  String copy_path = copy_string(path, NULL);
  UI_BRIDGE_CALL(ui, screenshot, 3, ui, copy_path.data, INT2PTR(copy_path.size));
}

static void ui_bridge_default_colors_set_event(void **argv)
{
  UI *ui = UI(argv[0]);
  ui->default_colors_set(ui, PTR2INT(argv[1]), PTR2INT(argv[2]), PTR2INT(argv[3]), PTR2INT(argv[4]), PTR2INT(argv[5]));
}

static void ui_bridge_default_colors_set(UI *ui, Integer rgb_fg, Integer rgb_bg, Integer rgb_sp, Integer cterm_fg, Integer cterm_bg)
{
  UI_BRIDGE_CALL(ui, default_colors_set, 6, ui, INT2PTR(rgb_fg), INT2PTR(rgb_bg), INT2PTR(rgb_sp), INT2PTR(cterm_fg), INT2PTR(cterm_bg));
}

static void ui_bridge_grid_resize_event(void **argv)
{
  UI *ui = UI(argv[0]);
  ui->grid_resize(ui, PTR2INT(argv[1]), PTR2INT(argv[2]), PTR2INT(argv[3]));
}

static void ui_bridge_grid_resize(UI *ui, Integer grid, Integer width, Integer height)
{
  UI_BRIDGE_CALL(ui, grid_resize, 4, ui, INT2PTR(grid), INT2PTR(width), INT2PTR(height));
}

static void ui_bridge_grid_clear_event(void **argv)
{
  UI *ui = UI(argv[0]);
  ui->grid_clear(ui, PTR2INT(argv[1]));
}

static void ui_bridge_grid_clear(UI *ui, Integer grid)
{
  UI_BRIDGE_CALL(ui, grid_clear, 2, ui, INT2PTR(grid));
}

static void ui_bridge_grid_cursor_goto_event(void **argv)
{
  UI *ui = UI(argv[0]);
  ui->grid_cursor_goto(ui, PTR2INT(argv[1]), PTR2INT(argv[2]), PTR2INT(argv[3]));
}

static void ui_bridge_grid_cursor_goto(UI *ui, Integer grid, Integer row, Integer col)
{
  UI_BRIDGE_CALL(ui, grid_cursor_goto, 4, ui, INT2PTR(grid), INT2PTR(row), INT2PTR(col));
}

static void ui_bridge_grid_scroll_event(void **argv)
{
  UI *ui = UI(argv[0]);
  ui->grid_scroll(ui, PTR2INT(argv[1]), PTR2INT(argv[2]), PTR2INT(argv[3]), PTR2INT(argv[4]), PTR2INT(argv[5]), PTR2INT(argv[6]), PTR2INT(argv[7]));
}

static void ui_bridge_grid_scroll(UI *ui, Integer grid, Integer top, Integer bot, Integer left, Integer right, Integer rows, Integer cols)
{
  UI_BRIDGE_CALL(ui, grid_scroll, 8, ui, INT2PTR(grid), INT2PTR(top), INT2PTR(bot), INT2PTR(left), INT2PTR(right), INT2PTR(rows), INT2PTR(cols));
}
