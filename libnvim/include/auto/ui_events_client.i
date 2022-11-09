# 1 "/Users/foxacid/ghq/github.com/foxacid7cd/Nims/Targets/libNims/build/src/nvim/auto/ui_events_client.generated.h"
# 1 "<built-in>" 1
# 1 "<built-in>" 3
# 400 "<built-in>" 3
# 1 "<command line>" 1
# 1 "<built-in>" 2
# 1 "/Users/foxacid/ghq/github.com/foxacid7cd/Nims/Targets/libNims/build/src/nvim/auto/ui_events_client.generated.h" 2
void ui_client_event_mode_info_set(Array args)
{
  if (args.size < 2
      || args.items[0].type != kObjectTypeBoolean
      || args.items[1].type != kObjectTypeArray) {
    ELOG("Error handling ui event 'mode_info_set'");
    return;
  }
  Boolean arg_1 = args.items[0].data.boolean;
  Array arg_2 = args.items[1].data.array;
  ui_call_mode_info_set(arg_1, arg_2);
}

void ui_client_event_update_menu(Array args)
{
  ui_call_update_menu();
}

void ui_client_event_busy_start(Array args)
{
  ui_call_busy_start();
}

void ui_client_event_busy_stop(Array args)
{
  ui_call_busy_stop();
}

void ui_client_event_mouse_on(Array args)
{
  ui_call_mouse_on();
}

void ui_client_event_mouse_off(Array args)
{
  ui_call_mouse_off();
}

void ui_client_event_mode_change(Array args)
{
  if (args.size < 2
      || args.items[0].type != kObjectTypeString
      || args.items[1].type != kObjectTypeInteger) {
    ELOG("Error handling ui event 'mode_change'");
    return;
  }
  String arg_1 = args.items[0].data.string;
  Integer arg_2 = args.items[1].data.integer;
  ui_call_mode_change(arg_1, arg_2);
}

void ui_client_event_bell(Array args)
{
  ui_call_bell();
}

void ui_client_event_visual_bell(Array args)
{
  ui_call_visual_bell();
}

void ui_client_event_flush(Array args)
{
  ui_call_flush();
}

void ui_client_event_suspend(Array args)
{
  ui_call_suspend();
}

void ui_client_event_set_title(Array args)
{
  if (args.size < 1
      || args.items[0].type != kObjectTypeString) {
    ELOG("Error handling ui event 'set_title'");
    return;
  }
  String arg_1 = args.items[0].data.string;
  ui_call_set_title(arg_1);
}

void ui_client_event_set_icon(Array args)
{
  if (args.size < 1
      || args.items[0].type != kObjectTypeString) {
    ELOG("Error handling ui event 'set_icon'");
    return;
  }
  String arg_1 = args.items[0].data.string;
  ui_call_set_icon(arg_1);
}

void ui_client_event_screenshot(Array args)
{
  if (args.size < 1
      || args.items[0].type != kObjectTypeString) {
    ELOG("Error handling ui event 'screenshot'");
    return;
  }
  String arg_1 = args.items[0].data.string;
  ui_call_screenshot(arg_1);
}

void ui_client_event_option_set(Array args)
{
  if (args.size < 2
      || args.items[0].type != kObjectTypeString) {
    ELOG("Error handling ui event 'option_set'");
    return;
  }
  String arg_1 = args.items[0].data.string;
  Object arg_2 = args.items[1];
  ui_call_option_set(arg_1, arg_2);
}

void ui_client_event_default_colors_set(Array args)
{
  if (args.size < 5
      || args.items[0].type != kObjectTypeInteger
      || args.items[1].type != kObjectTypeInteger
      || args.items[2].type != kObjectTypeInteger
      || args.items[3].type != kObjectTypeInteger
      || args.items[4].type != kObjectTypeInteger) {
    ELOG("Error handling ui event 'default_colors_set'");
    return;
  }
  Integer arg_1 = args.items[0].data.integer;
  Integer arg_2 = args.items[1].data.integer;
  Integer arg_3 = args.items[2].data.integer;
  Integer arg_4 = args.items[3].data.integer;
  Integer arg_5 = args.items[4].data.integer;
  ui_call_default_colors_set(arg_1, arg_2, arg_3, arg_4, arg_5);
}

void ui_client_event_hl_attr_define(Array args)
{
  if (args.size < 4
      || args.items[0].type != kObjectTypeInteger
      || args.items[1].type != kObjectTypeDictionary
      || args.items[2].type != kObjectTypeDictionary
      || args.items[3].type != kObjectTypeArray) {
    ELOG("Error handling ui event 'hl_attr_define'");
    return;
  }
  Integer arg_1 = args.items[0].data.integer;
  HlAttrs arg_2 = ui_client_dict2hlattrs(args.items[1].data.dictionary, true);
  HlAttrs arg_3 = ui_client_dict2hlattrs(args.items[2].data.dictionary, false);
  Array arg_4 = args.items[3].data.array;
  ui_call_hl_attr_define(arg_1, arg_2, arg_3, arg_4);
}

void ui_client_event_hl_group_set(Array args)
{
  if (args.size < 2
      || args.items[0].type != kObjectTypeString
      || args.items[1].type != kObjectTypeInteger) {
    ELOG("Error handling ui event 'hl_group_set'");
    return;
  }
  String arg_1 = args.items[0].data.string;
  Integer arg_2 = args.items[1].data.integer;
  ui_call_hl_group_set(arg_1, arg_2);
}

void ui_client_event_grid_clear(Array args)
{
  if (args.size < 1
      || args.items[0].type != kObjectTypeInteger) {
    ELOG("Error handling ui event 'grid_clear'");
    return;
  }
  Integer arg_1 = args.items[0].data.integer;
  ui_call_grid_clear(arg_1);
}

void ui_client_event_grid_cursor_goto(Array args)
{
  if (args.size < 3
      || args.items[0].type != kObjectTypeInteger
      || args.items[1].type != kObjectTypeInteger
      || args.items[2].type != kObjectTypeInteger) {
    ELOG("Error handling ui event 'grid_cursor_goto'");
    return;
  }
  Integer arg_1 = args.items[0].data.integer;
  Integer arg_2 = args.items[1].data.integer;
  Integer arg_3 = args.items[2].data.integer;
  ui_call_grid_cursor_goto(arg_1, arg_2, arg_3);
}

void ui_client_event_grid_scroll(Array args)
{
  if (args.size < 7
      || args.items[0].type != kObjectTypeInteger
      || args.items[1].type != kObjectTypeInteger
      || args.items[2].type != kObjectTypeInteger
      || args.items[3].type != kObjectTypeInteger
      || args.items[4].type != kObjectTypeInteger
      || args.items[5].type != kObjectTypeInteger
      || args.items[6].type != kObjectTypeInteger) {
    ELOG("Error handling ui event 'grid_scroll'");
    return;
  }
  Integer arg_1 = args.items[0].data.integer;
  Integer arg_2 = args.items[1].data.integer;
  Integer arg_3 = args.items[2].data.integer;
  Integer arg_4 = args.items[3].data.integer;
  Integer arg_5 = args.items[4].data.integer;
  Integer arg_6 = args.items[5].data.integer;
  Integer arg_7 = args.items[6].data.integer;
  ui_call_grid_scroll(arg_1, arg_2, arg_3, arg_4, arg_5, arg_6, arg_7);
}

void ui_client_event_msg_set_pos(Array args)
{
  if (args.size < 4
      || args.items[0].type != kObjectTypeInteger
      || args.items[1].type != kObjectTypeInteger
      || args.items[2].type != kObjectTypeBoolean
      || args.items[3].type != kObjectTypeString) {
    ELOG("Error handling ui event 'msg_set_pos'");
    return;
  }
  Integer arg_1 = args.items[0].data.integer;
  Integer arg_2 = args.items[1].data.integer;
  Boolean arg_3 = args.items[2].data.boolean;
  String arg_4 = args.items[3].data.string;
  ui_call_msg_set_pos(arg_1, arg_2, arg_3, arg_4);
}

void ui_client_event_win_viewport(Array args)
{
  if (args.size < 7
      || args.items[0].type != kObjectTypeInteger
      || args.items[1].type != kObjectTypeWindow
      || args.items[2].type != kObjectTypeInteger
      || args.items[3].type != kObjectTypeInteger
      || args.items[4].type != kObjectTypeInteger
      || args.items[5].type != kObjectTypeInteger
      || args.items[6].type != kObjectTypeInteger) {
    ELOG("Error handling ui event 'win_viewport'");
    return;
  }
  Integer arg_1 = args.items[0].data.integer;
  Window arg_2 = (Window)args.items[1].data.integer;
  Integer arg_3 = args.items[2].data.integer;
  Integer arg_4 = args.items[3].data.integer;
  Integer arg_5 = args.items[4].data.integer;
  Integer arg_6 = args.items[5].data.integer;
  Integer arg_7 = args.items[6].data.integer;
  ui_call_win_viewport(arg_1, arg_2, arg_3, arg_4, arg_5, arg_6, arg_7);
}

void ui_client_event_wildmenu_show(Array args)
{
  if (args.size < 1
      || args.items[0].type != kObjectTypeArray) {
    ELOG("Error handling ui event 'wildmenu_show'");
    return;
  }
  Array arg_1 = args.items[0].data.array;
  ui_call_wildmenu_show(arg_1);
}

void ui_client_event_wildmenu_select(Array args)
{
  if (args.size < 1
      || args.items[0].type != kObjectTypeInteger) {
    ELOG("Error handling ui event 'wildmenu_select'");
    return;
  }
  Integer arg_1 = args.items[0].data.integer;
  ui_call_wildmenu_select(arg_1);
}

void ui_client_event_wildmenu_hide(Array args)
{
  ui_call_wildmenu_hide();
}

static const UIClientHandler event_handlers[] = {
  { .name = "bell", .fn = ui_client_event_bell},
  { .name = "flush", .fn = ui_client_event_flush},
  { .name = "suspend", .fn = ui_client_event_suspend},
  { .name = "mouse_on", .fn = ui_client_event_mouse_on},
  { .name = "set_icon", .fn = ui_client_event_set_icon},
  { .name = "busy_stop", .fn = ui_client_event_busy_stop},
  { .name = "grid_line", .fn = ui_client_event_grid_line},
  { .name = "mouse_off", .fn = ui_client_event_mouse_off},
  { .name = "set_title", .fn = ui_client_event_set_title},
  { .name = "busy_start", .fn = ui_client_event_busy_start},
  { .name = "grid_clear", .fn = ui_client_event_grid_clear},
  { .name = "option_set", .fn = ui_client_event_option_set},
  { .name = "screenshot", .fn = ui_client_event_screenshot},
  { .name = "msg_set_pos", .fn = ui_client_event_msg_set_pos},
  { .name = "mode_change", .fn = ui_client_event_mode_change},
  { .name = "visual_bell", .fn = ui_client_event_visual_bell},
  { .name = "update_menu", .fn = ui_client_event_update_menu},
  { .name = "grid_scroll", .fn = ui_client_event_grid_scroll},
  { .name = "grid_resize", .fn = ui_client_event_grid_resize},
  { .name = "hl_group_set", .fn = ui_client_event_hl_group_set},
  { .name = "win_viewport", .fn = ui_client_event_win_viewport},
  { .name = "mode_info_set", .fn = ui_client_event_mode_info_set},
  { .name = "wildmenu_hide", .fn = ui_client_event_wildmenu_hide},
  { .name = "wildmenu_show", .fn = ui_client_event_wildmenu_show},
  { .name = "hl_attr_define", .fn = ui_client_event_hl_attr_define},
  { .name = "wildmenu_select", .fn = ui_client_event_wildmenu_select},
  { .name = "grid_cursor_goto", .fn = ui_client_event_grid_cursor_goto},
  { .name = "default_colors_set", .fn = ui_client_event_default_colors_set},

};

int ui_client_handler_hash(const char *str, size_t len)
{
  int low = -1;
  switch (len) {
    case 4: low = 0; break;
    case 5: low = 1; break;
    case 7: low = 2; break;
    case 8: switch (str[0]) {
      case 'm': low = 3; break;
      case 's': low = 4; break;
      default: break;
    }
    break;
    case 9: switch (str[0]) {
      case 'b': low = 5; break;
      case 'g': low = 6; break;
      case 'm': low = 7; break;
      case 's': low = 8; break;
      default: break;
    }
    break;
    case 10: switch (str[0]) {
      case 'b': low = 9; break;
      case 'g': low = 10; break;
      case 'o': low = 11; break;
      case 's': low = 12; break;
      default: break;
    }
    break;
    case 11: switch (str[7]) {
      case '_': low = 13; break;
      case 'a': low = 14; break;
      case 'b': low = 15; break;
      case 'm': low = 16; break;
      case 'r': low = 17; break;
      case 's': low = 18; break;
      default: break;
    }
    break;
    case 12: switch (str[0]) {
      case 'h': low = 19; break;
      case 'w': low = 20; break;
      default: break;
    }
    break;
    case 13: switch (str[9]) {
      case '_': low = 21; break;
      case 'h': low = 22; break;
      case 's': low = 23; break;
      default: break;
    }
    break;
    case 14: low = 24; break;
    case 15: low = 25; break;
    case 16: low = 26; break;
    case 18: low = 27; break;
    default: break;
  }
  if (low < 0 || memcmp(str, event_handlers[low].name, len)) {
    return -1;
  }
  return low;
}
