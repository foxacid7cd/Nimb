#define DEFINE_FUNC_ATTRIBUTES
#include "nvim/func_attr.h"
#undef DEFINE_FUNC_ATTRIBUTES
static void ui_bridge_mode_info_set_event(void **argv);
static void ui_bridge_mode_info_set(UI *ui, Boolean enabled, Array cursor_styles);
static void ui_bridge_update_menu_event(void **argv);
static void ui_bridge_update_menu(UI *ui);
static void ui_bridge_busy_start_event(void **argv);
static void ui_bridge_busy_start(UI *ui);
static void ui_bridge_busy_stop_event(void **argv);
static void ui_bridge_busy_stop(UI *ui);
static void ui_bridge_mouse_on_event(void **argv);
static void ui_bridge_mouse_on(UI *ui);
static void ui_bridge_mouse_off_event(void **argv);
static void ui_bridge_mouse_off(UI *ui);
static void ui_bridge_mode_change_event(void **argv);
static void ui_bridge_mode_change(UI *ui, String mode, Integer mode_idx);
static void ui_bridge_bell_event(void **argv);
static void ui_bridge_bell(UI *ui);
static void ui_bridge_visual_bell_event(void **argv);
static void ui_bridge_visual_bell(UI *ui);
static void ui_bridge_flush_event(void **argv);
static void ui_bridge_flush(UI *ui);
static void ui_bridge_set_title_event(void **argv);
static void ui_bridge_set_title(UI *ui, String title);
static void ui_bridge_set_icon_event(void **argv);
static void ui_bridge_set_icon(UI *ui, String icon);
static void ui_bridge_screenshot_event(void **argv);
static void ui_bridge_screenshot(UI *ui, String path);
static void ui_bridge_default_colors_set_event(void **argv);
static void ui_bridge_default_colors_set(UI *ui, Integer rgb_fg, Integer rgb_bg, Integer rgb_sp, Integer cterm_fg, Integer cterm_bg);
static void ui_bridge_grid_resize_event(void **argv);
static void ui_bridge_grid_resize(UI *ui, Integer grid, Integer width, Integer height);
static void ui_bridge_grid_clear_event(void **argv);
static void ui_bridge_grid_clear(UI *ui, Integer grid);
static void ui_bridge_grid_cursor_goto_event(void **argv);
static void ui_bridge_grid_cursor_goto(UI *ui, Integer grid, Integer row, Integer col);
static void ui_bridge_grid_scroll_event(void **argv);
static void ui_bridge_grid_scroll(UI *ui, Integer grid, Integer top, Integer bot, Integer left, Integer right, Integer rows, Integer cols);
#include "nvim/func_attr.h"
