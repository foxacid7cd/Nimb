#define DEFINE_FUNC_ATTRIBUTES
#include "nvim/func_attr.h"
#undef DEFINE_FUNC_ATTRIBUTES
static void remote_ui_mode_info_set(UI *ui, Boolean enabled, Array cursor_styles);
static void remote_ui_update_menu(UI *ui);
static void remote_ui_busy_start(UI *ui);
static void remote_ui_busy_stop(UI *ui);
static void remote_ui_mouse_on(UI *ui);
static void remote_ui_mouse_off(UI *ui);
static void remote_ui_mode_change(UI *ui, String mode, Integer mode_idx);
static void remote_ui_bell(UI *ui);
static void remote_ui_visual_bell(UI *ui);
static void remote_ui_suspend(UI *ui);
static void remote_ui_set_title(UI *ui, String title);
static void remote_ui_set_icon(UI *ui, String icon);
static void remote_ui_option_set(UI *ui, String name, Object value);
static void remote_ui_hl_group_set(UI *ui, String name, Integer id);
static void remote_ui_msg_set_pos(UI *ui, Integer grid, Integer row, Boolean scrolled, String sep_char);
static void remote_ui_win_viewport(UI *ui, Integer grid, Window win, Integer topline, Integer botline, Integer curline, Integer curcol, Integer line_count);
#include "nvim/func_attr.h"
