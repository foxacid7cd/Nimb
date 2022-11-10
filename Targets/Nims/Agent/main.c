//
//  main.c
//  Agent
//
//  Created by Yevhenii Matviienko on 09.11.2022.
//  Copyright © 2022 foxacid7cd. All rights reserved.
//

#include <xpc/xpc.h>
#include <nvim/event/loop.h>
#include <nvim/ui_bridge.h>
#include <nvim/ui.h>
#include <uv.h>
#include "AgentLibrary.h"
#include "main.h"

extern Loop main_loop;

extern int nvim_main(int argc, char **argv);

agent_bridge_data_t agent_bridge_data;

uv_thread_t nvim_thread;

xpc_connection_t active_xpc_connection;

void nvim_thread_entry(void *arg)
{
  char *nvim_arguments[1];
  nvim_arguments[0] = "nvim";
  //nvim_arguments[1] = "--headless";
  
  nvim_main(1, nvim_arguments);
}

void handle_mode_info_set(UI *ui, bool enabled, Array cursor_styles)
{}

void handle_update_menu(UI *ui)
{}

void handle_busy_start(UI *ui)
{}

void handle_busy_stop(UI *ui)
{}

void handle_mouse_on(UI *ui)
{}

void handle_mouse_off(UI *ui)
{}

void handle_mode_change(UI *ui, String mode, Integer mode_idx)
{}

void handle_bell(UI *ui)
{}

void handle_visual_bell(UI *ui)
{}

void handle_flush(UI *ui)
{}

void handle_suspend(UI *ui)
{}

void handle_set_title(UI *ui, String title)
{}

void handle_set_icon(UI *ui, String icon)
{}

void handle_screenshot(UI *ui, String path)
{}

void handle_option_set(UI *ui, String name, Object value)
{}

void handle_stop(UI *ui)
{}

void handle_default_colors_set(UI *ui, Integer rgb_fg, Integer rgb_bg, Integer rgb_sp, Integer cterm_fg, Integer cterm_bg)
{}

void handle_hl_attr_define(UI *ui, Integer id, HlAttrs rgb_attrs, HlAttrs cterm_attrs, Array info)
{}

void handle_hl_group_set(UI *ui, String name, Integer id)
{}

void handle_grid_resize(UI *ui, Integer grid, Integer width, Integer height)
{}

void handle_grid_clear(UI *ui, Integer grid)
{}

void handle_grid_cursor_goto(UI *ui, Integer grid, Integer row, Integer col)
{}

void handle_grid_scroll(UI *ui, Integer grid, Integer top, Integer bot, Integer left, Integer right, Integer rows, Integer cols)
{}

void handle_raw_line(UI *ui, Integer grid, Integer row, Integer startcol, Integer endcol, Integer clearcol, Integer clearattr, LineFlags flags, const schar_T * chunk, const sattr_T * attrs)
{}

void handle_event(UI *ui, char * name, Array args)
{}

void handle_msg_set_pos(UI *ui, Integer grid, Integer row, bool scrolled, String sep_char)
{}

void handle_win_viewport(UI *ui, Integer grid, Window win, Integer topline, Integer botline, Integer curline, Integer curcol, Integer line_count)
{}

void handle_wildmenu_show(UI *ui, Array items)
{}

void handle_wildmenu_select(UI *ui, Integer selected)
{}

void handle_wildmenu_hide(UI *ui)
{}

static void agent_ui_main(UIBridgeData *bridge, UI *ui)
{
  Loop loop;
  loop_init(&loop, NULL);
  
  ui->data = &agent_bridge_data;
  agent_bridge_data.bridge = bridge;
  agent_bridge_data.loop = &loop;
  
  agent_bridge_data.stop = false;
  CONTINUE(bridge);
  
  while (!agent_bridge_data.stop) {
    loop_poll_events(&loop, -1);
  }
  
  ui_bridge_stopped(bridge);
  loop_close(&loop, false);
}

static void agent_ui_scheduler(Event event, void *d)
{
  UI *ui = d;
  agent_bridge_data_t *data = ui->data;
  loop_schedule_fast(data->loop, event);
}

void ui_builtin_start(void)
{
  UI *ui = malloc(sizeof(UI));
  
  memset(ui->ui_ext, 0, sizeof(ui->ui_ext));
  ui->ui_ext[kUIMultigrid] = true;
  ui->ui_ext[kUIMessages] = true;
  ui->ui_ext[kUICmdline] = true;
  
  ui->rgb = true;
  ui->width = agent_bridge_data.init_width;
  ui->height = agent_bridge_data.init_height;
  
  ui->mode_info_set = handle_mode_info_set;
  ui->update_menu = handle_update_menu;
  ui->busy_start = handle_busy_start;
  ui->busy_stop = handle_busy_stop;
  ui->mouse_on = handle_mouse_on;
  ui->mouse_off = handle_mouse_off;
  ui->mode_change = handle_mode_change;
  ui->bell = handle_bell;
  ui->visual_bell = handle_visual_bell;
  ui->flush = handle_flush;
  ui->suspend = handle_suspend;
  ui->set_title = handle_set_title;
  ui->set_icon = handle_set_icon;
  ui->screenshot = handle_screenshot;
  ui->option_set = handle_option_set;
  ui->stop = handle_stop;
  ui->default_colors_set = handle_default_colors_set;
  ui->hl_attr_define = handle_hl_attr_define;
  ui->hl_group_set = handle_hl_group_set;
  ui->grid_resize = handle_grid_resize;
  ui->grid_clear = handle_grid_clear;
  ui->grid_cursor_goto = handle_grid_cursor_goto;
  ui->grid_scroll = handle_grid_scroll;
  ui->raw_line = handle_raw_line;
  ui->event = handle_event;
  ui->msg_set_pos = handle_msg_set_pos;
  ui->win_viewport = handle_win_viewport;
  ui->wildmenu_show = handle_wildmenu_show;
  ui->wildmenu_select = handle_wildmenu_select;
  ui->wildmenu_hide = handle_wildmenu_hide;
  
  ui_bridge_attach(ui, agent_ui_main, agent_ui_scheduler);
}

void handle_input_message_data(xpc_object_t data)
{
  int64_t message_type = xpc_array_get_int64(data, 0);
  
  switch (message_type) {
    case AgentInputMessageTypeStart: {
      agent_bridge_data.init_width = (int) xpc_array_get_int64(data, 1);
      agent_bridge_data.init_height = (int) xpc_array_get_int64(data, 2);
      
      uv_thread_create(&nvim_thread, nvim_thread_entry, NULL);
    }
      
    default:
      break;
  }
}

void handle_connection(xpc_connection_t connection)
{
  if (active_xpc_connection != NULL) {
    return xpc_connection_cancel(connection);
  }
  
  active_xpc_connection = connection;
  
  xpc_connection_set_event_handler(connection, ^(xpc_object_t object) {
    xpc_type_t type = xpc_get_type(object);
    
    if (type == XPC_TYPE_ERROR) {
      const char *description = xpc_dictionary_get_string(object, XPC_ERROR_KEY_DESCRIPTION);
      printf("XPC error: %s\n", description);
  
      return;
    }
    
    xpc_object_t data = xpc_dictionary_get_array(object, AGENT_MESSAGE_DATA_KEY);
    handle_input_message_data(data);
    
    xpc_object_t reply_data = xpc_array_create_empty();
    xpc_array_append_value(reply_data, xpc_bool_create(true));
    
    xpc_object_t reply_message = xpc_dictionary_create_reply(object);
    xpc_dictionary_set_value(reply_message, AGENT_MESSAGE_DATA_KEY, reply_data);
    
    xpc_connection_send_message(connection, reply_message);
  });
  
  xpc_connection_activate(connection);
}

int main(int argc, char **argv)
{
  xpc_main(handle_connection);
}
