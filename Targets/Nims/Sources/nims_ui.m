//
//  nims_ui.m
//  Nims
//
//  Created by Yevhenii Matviienko on 10.11.2022.
//  Copyright © 2022 foxacid7cd. All rights reserved.
//

#include <nvim/ui_bridge.h>
#import "nims_ui.h"

typedef struct {
  UIBridgeData *bridge;
  Loop *loop;
  
  bool stop;
  
  int init_width;
  int init_height;
} nims_ui_data_t;

nims_ui_data_t *nims_ui_data;

void nims_ui_event_mode_info_set(UI *ui, bool enabled, Array cursor_styles)
{}

void nims_ui_event_update_menu(UI *ui)
{}

void nims_ui_event_busy_start(UI *ui)
{}

void nims_ui_event_busy_stop(UI *ui)
{}

void nims_ui_event_mouse_on(UI *ui)
{}

void nims_ui_event_mouse_off(UI *ui)
{}

void nims_ui_event_mode_change(UI *ui, String mode, Integer mode_idx)
{}

void nims_ui_event_bell(UI *ui)
{}

void nims_ui_event_visual_bell(UI *ui)
{}

void nims_ui_event_flush(UI *ui)
{}

void nims_ui_event_suspend(UI *ui)
{}

void nims_ui_event_set_title(UI *ui, String title)
{}

void nims_ui_event_set_icon(UI *ui, String icon)
{}

void nims_ui_event_screenshot(UI *ui, String path)
{}

void nims_ui_event_option_set(UI *ui, String name, Object value)
{}

void nims_ui_event_stop(UI *ui)
{}

void nims_ui_event_default_colors_set(UI *ui, Integer rgb_fg, Integer rgb_bg, Integer rgb_sp, Integer cterm_fg, Integer cterm_bg)
{}

void nims_ui_event_hl_attr_define(UI *ui, Integer id, HlAttrs rgb_attrs, HlAttrs cterm_attrs, Array info)
{}

void nims_ui_event_hl_group_set(UI *ui, String name, Integer id)
{}

void nims_ui_event_grid_resize(UI *ui, Integer grid, Integer width, Integer height)
{}

void nims_ui_event_grid_clear(UI *ui, Integer grid)
{}

void nims_ui_event_grid_cursor_goto(UI *ui, Integer grid, Integer row, Integer col)
{}

void nims_ui_event_grid_scroll(UI *ui, Integer grid, Integer top, Integer bot, Integer left, Integer right, Integer rows, Integer cols)
{}

void nims_ui_event_raw_line(UI *ui, Integer grid, Integer row, Integer startcol, Integer endcol, Integer clearcol, Integer clearattr, LineFlags flags, const schar_T * chunk, const sattr_T * attrs)
{}

void nims_ui_event_event(UI *ui, char * name, Array args)
{}

void nims_ui_event_msg_set_pos(UI *ui, Integer grid, Integer row, bool scrolled, String sep_char)
{}

void nims_ui_event_win_viewport(UI *ui, Integer grid, Window win, Integer topline, Integer botline, Integer curline, Integer curcol, Integer line_count)
{}

void nims_ui_event_wildmenu_show(UI *ui, Array items)
{}

void nims_ui_event_wildmenu_select(UI *ui, Integer selected)
{}

void nims_ui_event_wildmenu_hide(UI *ui)
{}

static void nims_ui_event_scheduler(Event event, void *data)
{
  UI *ui = data;
  nims_ui_data_t *bridge_data = ui->data;
  loop_schedule_fast(bridge_data->loop, event);
}

static void nims_ui_event_main(UIBridgeData *bridge, UI *ui)
{
  bridge->ui = ui;
  
  Loop loop;
  loop_init(&loop, NULL);
  
  nims_ui_data_t *ui_data = ui->data;
  ui_data->loop = &loop;
  
  ui_data->stop = false;
  CONTINUE(bridge);
  
  while (!ui_data->stop) {
    loop_poll_events(&loop, -1);
  }
  
  ui_bridge_stopped(bridge);
  loop_close(&loop, false);
}

void nims_ui_attach(int width, int height)
{
  assert(nims_ui_data == NULL);
  
  UI *ui = malloc(sizeof(UI));
  
  memset(ui->ui_ext, 0, sizeof(ui->ui_ext));
  ui->ui_ext[kUIMultigrid] = true;
  ui->ui_ext[kUIMessages] = true;
  ui->ui_ext[kUICmdline] = true;
  
  ui->rgb = true;
  ui->width = width;
  ui->height = height;
  
  ui->mode_info_set = nims_ui_event_mode_info_set;
  ui->update_menu = nims_ui_event_update_menu;
  ui->busy_start = nims_ui_event_busy_start;
  ui->busy_stop = nims_ui_event_busy_stop;
  ui->mouse_on = nims_ui_event_mouse_on;
  ui->mouse_off = nims_ui_event_mouse_off;
  ui->mode_change = nims_ui_event_mode_change;
  ui->bell = nims_ui_event_bell;
  ui->visual_bell = nims_ui_event_visual_bell;
  ui->flush = nims_ui_event_flush;
  ui->suspend = nims_ui_event_suspend;
  ui->set_title = nims_ui_event_set_title;
  ui->set_icon = nims_ui_event_set_icon;
  ui->screenshot = nims_ui_event_screenshot;
  ui->option_set = nims_ui_event_option_set;
  ui->stop = nims_ui_event_stop;
  ui->default_colors_set = nims_ui_event_default_colors_set;
  ui->hl_attr_define = nims_ui_event_hl_attr_define;
  ui->hl_group_set = nims_ui_event_hl_group_set;
  ui->grid_resize = nims_ui_event_grid_resize;
  ui->grid_clear = nims_ui_event_grid_clear;
  ui->grid_cursor_goto = nims_ui_event_grid_cursor_goto;
  ui->grid_scroll = nims_ui_event_grid_scroll;
  ui->raw_line = nims_ui_event_raw_line;
  ui->event = nims_ui_event_event;
  ui->msg_set_pos = nims_ui_event_msg_set_pos;
  ui->win_viewport = nims_ui_event_win_viewport;
  ui->wildmenu_show = nims_ui_event_wildmenu_show;
  ui->wildmenu_select = nims_ui_event_wildmenu_select;
  ui->wildmenu_hide = nims_ui_event_wildmenu_hide;
  
  nims_ui_data = malloc(sizeof(nims_ui_data_t));
  nims_ui_data->init_width = width;
  nims_ui_data->init_height = height;
  ui->data = nims_ui_data;
  
  ui_bridge_attach(ui, nims_ui_event_main, nims_ui_event_scheduler);
}
