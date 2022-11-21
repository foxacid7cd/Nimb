//
//  nims_ui.c
//  nvims
//
//  Created by Yevhenii Matviienko on 11.11.2022.
//  Copyright © 2022 foxacid7cd. All rights reserved.
//

#include <dispatch/base.h>
#include <nvim/ui.h>
#include <nvim/ui_bridge.h>
#include <sys/param.h>
#include "nvims.h"

extern nvims_ui_t nvims_ui;

typedef struct {
  UIBridgeData *bridge;
  Loop *loop;
} NimsUIData;

#define STRING(arg)   *(nvim_string_t *)&arg
#define OBJECT(arg)   *(nvim_object_t *)&arg
#define ARRAY(arg)    *(nvim_array_t *)&arg
#define HL_ATTRS(arg) *(nvim_hl_attrs_t *)&arg

void nims_ui_mode_info_set(UI *ui, bool enabled, Array cursor_styles) {
  nvims_ui.mode_info_set(enabled, ARRAY(cursor_styles));
}

void nims_ui_update_menu(UI *ui) {
  nvims_ui.update_menu();
}

void nims_ui_busy_start(UI *ui) {
  nvims_ui.busy_start();
}

void nims_ui_busy_stop(UI *ui) {
  nvims_ui.busy_stop();
}

void nims_ui_mouse_on(UI *ui) {
  nvims_ui.mouse_on();
}

void nims_ui_mouse_off(UI *ui) {
  nvims_ui.mouse_off();
}

void nims_ui_mode_change(UI *ui, String mode, Integer mode_idx) {
  nvims_ui.mode_change(STRING(mode), mode_idx);
}

void nims_ui_bell(UI *ui) {
  nvims_ui.bell();
}

void nims_ui_visual_bell(UI *ui) {
  nvims_ui.visual_bell();
}

void nims_ui_flush(UI *ui) {
  nvims_ui.flush();
}

void nims_ui_suspend(UI *ui) {
  nvims_ui.suspend();
}

void nims_ui_set_title(UI *ui, String title) {
  nvims_ui.set_title(STRING(title));
}

void nims_ui_set_icon(UI *ui, String icon) {
  nvims_ui.set_icon(STRING(icon));
}

void nims_ui_screenshot(UI *ui, String path) {
  nvims_ui.screenshot(STRING(path));
}

void nims_ui_option_set(UI *ui, String name, Object value) {
  nvims_ui.option_set(STRING(name), OBJECT(value));
}

void nims_ui_stop(UI *ui) {
  nvims_ui.stop();
}

void nims_ui_default_colors_set(UI *ui, Integer rgb_fg, Integer rgb_bg, Integer rgb_sp, Integer cterm_fg, Integer cterm_bg) {
  nvims_ui.default_colors_set(rgb_fg, rgb_bg, rgb_sp, cterm_fg, cterm_bg);
}

void nims_ui_hl_attr_define(UI *ui, Integer id, HlAttrs rgb_attrs, HlAttrs cterm_attrs, Array info) {
  nvims_ui.hl_attr_define(id, HL_ATTRS(rgb_attrs), HL_ATTRS(cterm_attrs), ARRAY(info));
}

void nims_ui_hl_group_set(UI *ui, String name, Integer id) {
  nvims_ui.hl_group_set(STRING(name), id);
}

void nims_ui_grid_resize(UI *ui, Integer grid, Integer width, Integer height) {
  nvims_ui.grid_resize(grid, width, height);
}

void nims_ui_grid_clear(UI *ui, Integer grid) {
  nvims_ui.grid_clear(grid);
}

void nims_ui_grid_cursor_goto(UI *ui, Integer grid, Integer row, Integer col) {
  nvims_ui.grid_cursor_goto(grid, row, col);
}

void nims_ui_grid_scroll(UI *ui, Integer grid, Integer top, Integer bot, Integer left, Integer right, Integer rows, Integer cols) {
  nvims_ui.grid_scroll(grid, top, bot, left, right, rows, cols);
}

void nims_ui_raw_line(UI *ui, Integer grid, Integer row, Integer startcol, Integer endcol, Integer clearcol, Integer clearattr, LineFlags flags, const schar_T *chunk, const sattr_T *attrs) {
  nvims_ui.raw_line(grid, row, startcol, endcol, clearcol, clearattr, flags, chunk, attrs);
}

void nims_ui_event(UI *ui, char *name, Array args) {
  nvims_ui.event(name, ARRAY(args));
}

void nims_ui_msg_set_pos(UI *ui, Integer grid, Integer row, bool scrolled, String sep_char) {
  nvims_ui.msg_set_pos(grid, row, scrolled, STRING(sep_char));
}

void nims_ui_win_viewport(UI *ui, Integer grid, Window win, Integer topline, Integer botline, Integer curline, Integer curcol, Integer line_count) {
  nvims_ui.win_viewport(grid, win, topline, botline, curline, curcol, line_count);
}

void nims_ui_wildmenu_show(UI *ui, Array items) {
  nvims_ui.wildmenu_show(ARRAY(items));
}

void nims_ui_wildmenu_select(UI *ui, Integer selected) {
  nvims_ui.wildmenu_select(selected);
}

void nims_ui_wildmenu_hide(UI *ui) {
  nvims_ui.wildmenu_hide();
}

static void nims_ui_scheduler(Event event, void *arg) {
  UI *ui = arg;
  NimsUIData *data = ui->data;

  loop_schedule_fast(data->loop, event);
}

static void nims_ui_main(UIBridgeData *bridge, UI *ui) {
  Loop loop;

  loop_init(&loop, NULL);

  NimsUIData *data = xcalloc(1, sizeof(NimsUIData));
  ui->data = data;

  data->bridge = bridge;
  data->loop = &loop;

  CONTINUE(bridge);

  while (true)
    loop_poll_events(&loop, -1);
}

void nims_ui_start(void) {
  UI *ui = xcalloc(1, sizeof(UI));

  memset(ui->ui_ext, 0, sizeof(ui->ui_ext));
  ui->ui_ext[kUIHlState] = true;
  ui->ui_ext[kUIMultigrid] = true;
  ui->ui_ext[kUICmdline] = true;
  ui->ui_ext[kUIMessages] = true;
  ui->ui_ext[kUIWildmenu] = true;
  ui->ui_ext[kUIPopupmenu] = true;

  ui->rgb = true;
  ui->override = true;
  ui->width = nvims_ui.width;
  ui->height = nvims_ui.height;

  ui->mode_info_set = nims_ui_mode_info_set;
  ui->update_menu = nims_ui_update_menu;
  ui->busy_start = nims_ui_busy_start;
  ui->busy_stop = nims_ui_busy_stop;
  ui->mouse_on = nims_ui_mouse_on;
  ui->mouse_off = nims_ui_mouse_off;
  ui->mode_change = nims_ui_mode_change;
  ui->bell = nims_ui_bell;
  ui->visual_bell = nims_ui_visual_bell;
  ui->flush = nims_ui_flush;
  ui->suspend = nims_ui_suspend;
  ui->set_title = nims_ui_set_title;
  ui->set_icon = nims_ui_set_icon;
  ui->screenshot = nims_ui_screenshot;
  ui->option_set = nims_ui_option_set;
  ui->stop = nims_ui_stop;
  ui->default_colors_set = nims_ui_default_colors_set;
  ui->hl_attr_define = nims_ui_hl_attr_define;
  ui->hl_group_set = nims_ui_hl_group_set;
  ui->grid_resize = nims_ui_grid_resize;
  ui->grid_clear = nims_ui_grid_clear;
  ui->grid_cursor_goto = nims_ui_grid_cursor_goto;
  ui->grid_scroll = nims_ui_grid_scroll;
  ui->raw_line = nims_ui_raw_line;
  ui->event = nims_ui_event;
  ui->msg_set_pos = nims_ui_msg_set_pos;
  ui->win_viewport = nims_ui_win_viewport;
  ui->wildmenu_show = nims_ui_wildmenu_show;
  ui->wildmenu_select = nims_ui_wildmenu_select;
  ui->wildmenu_hide = nims_ui_wildmenu_hide;

  ui_bridge_attach(ui, nims_ui_main, nims_ui_scheduler);
}
