KeySetLink option_table[] = {
  {"buf", offsetof(KeyDict_option, buf)},
  {"win", offsetof(KeyDict_option, win)},
  {"scope", offsetof(KeyDict_option, scope)},
  {NULL, 0},
};

int option_hash(const char *str, size_t len)
{
  int low = -1;
  switch (len) {
    case 3: switch (str[0]) {
      case 'b': low = 0; break;
      case 'w': low = 1; break;
      default: break;
    }
    break;
    case 5: low = 2; break;
    default: break;
  }
  if (low < 0 || memcmp(str, option_table[low].str, len)) {
    return -1;
  }
  return low;
}

Object *KeyDict_option_get_field(void *retval, const char *str, size_t len)
{
  int hash = option_hash(str, len);
  if (hash == -1) {
    return NULL;
  }

  return (Object *)((char *)retval + option_table[hash].ptr_off);
}

KeySetLink create_autocmd_table[] = {
  {"desc", offsetof(KeyDict_create_autocmd, desc)},
  {"once", offsetof(KeyDict_create_autocmd, once)},
  {"group", offsetof(KeyDict_create_autocmd, group)},
  {"buffer", offsetof(KeyDict_create_autocmd, buffer)},
  {"nested", offsetof(KeyDict_create_autocmd, nested)},
  {"command", offsetof(KeyDict_create_autocmd, command)},
  {"pattern", offsetof(KeyDict_create_autocmd, pattern)},
  {"callback", offsetof(KeyDict_create_autocmd, callback)},
  {NULL, 0},
};

int create_autocmd_hash(const char *str, size_t len)
{
  int low = -1;
  switch (len) {
    case 4: switch (str[0]) {
      case 'd': low = 0; break;
      case 'o': low = 1; break;
      default: break;
    }
    break;
    case 5: low = 2; break;
    case 6: switch (str[0]) {
      case 'b': low = 3; break;
      case 'n': low = 4; break;
      default: break;
    }
    break;
    case 7: switch (str[0]) {
      case 'c': low = 5; break;
      case 'p': low = 6; break;
      default: break;
    }
    break;
    case 8: low = 7; break;
    default: break;
  }
  if (low < 0 || memcmp(str, create_autocmd_table[low].str, len)) {
    return -1;
  }
  return low;
}

Object *KeyDict_create_autocmd_get_field(void *retval, const char *str, size_t len)
{
  int hash = create_autocmd_hash(str, len);
  if (hash == -1) {
    return NULL;
  }

  return (Object *)((char *)retval + create_autocmd_table[hash].ptr_off);
}

KeySetLink highlight_table[] = {
  {"bg", offsetof(KeyDict_highlight, bg)},
  {"fg", offsetof(KeyDict_highlight, fg)},
  {"sp", offsetof(KeyDict_highlight, sp)},
  {"bold", offsetof(KeyDict_highlight, bold)},
  {"link", offsetof(KeyDict_highlight, link)},
  {"blend", offsetof(KeyDict_highlight, blend)},
  {"cterm", offsetof(KeyDict_highlight, cterm)},
  {"italic", offsetof(KeyDict_highlight, italic)},
  {"special", offsetof(KeyDict_highlight, special)},
  {"ctermbg", offsetof(KeyDict_highlight, ctermbg)},
  {"ctermfg", offsetof(KeyDict_highlight, ctermfg)},
  {"default", offsetof(KeyDict_highlight, default_)},
  {"reverse", offsetof(KeyDict_highlight, reverse)},
  {"fallback", offsetof(KeyDict_highlight, fallback)},
  {"standout", offsetof(KeyDict_highlight, standout)},
  {"nocombine", offsetof(KeyDict_highlight, nocombine)},
  {"undercurl", offsetof(KeyDict_highlight, undercurl)},
  {"underline", offsetof(KeyDict_highlight, underline)},
  {"background", offsetof(KeyDict_highlight, background)},
  {"foreground", offsetof(KeyDict_highlight, foreground)},
  {"global_link", offsetof(KeyDict_highlight, global_link)},
  {"underdashed", offsetof(KeyDict_highlight, underdashed)},
  {"underdotted", offsetof(KeyDict_highlight, underdotted)},
  {"underdouble", offsetof(KeyDict_highlight, underdouble)},
  {"strikethrough", offsetof(KeyDict_highlight, strikethrough)},
  {NULL, 0},
};

int highlight_hash(const char *str, size_t len)
{
  int low = -1;
  switch (len) {
    case 2: switch (str[0]) {
      case 'b': low = 0; break;
      case 'f': low = 1; break;
      case 's': low = 2; break;
      default: break;
    }
    break;
    case 4: switch (str[0]) {
      case 'b': low = 3; break;
      case 'l': low = 4; break;
      default: break;
    }
    break;
    case 5: switch (str[0]) {
      case 'b': low = 5; break;
      case 'c': low = 6; break;
      default: break;
    }
    break;
    case 6: low = 7; break;
    case 7: switch (str[5]) {
      case 'a': low = 8; break;
      case 'b': low = 9; break;
      case 'f': low = 10; break;
      case 'l': low = 11; break;
      case 's': low = 12; break;
      default: break;
    }
    break;
    case 8: switch (str[0]) {
      case 'f': low = 13; break;
      case 's': low = 14; break;
      default: break;
    }
    break;
    case 9: switch (str[5]) {
      case 'b': low = 15; break;
      case 'c': low = 16; break;
      case 'l': low = 17; break;
      default: break;
    }
    break;
    case 10: switch (str[0]) {
      case 'b': low = 18; break;
      case 'f': low = 19; break;
      default: break;
    }
    break;
    case 11: switch (str[7]) {
      case 'l': low = 20; break;
      case 's': low = 21; break;
      case 't': low = 22; break;
      case 'u': low = 23; break;
      default: break;
    }
    break;
    case 13: low = 24; break;
    default: break;
  }
  if (low < 0 || memcmp(str, highlight_table[low].str, len)) {
    return -1;
  }
  return low;
}

Object *KeyDict_highlight_get_field(void *retval, const char *str, size_t len)
{
  int hash = highlight_hash(str, len);
  if (hash == -1) {
    return NULL;
  }

  return (Object *)((char *)retval + highlight_table[hash].ptr_off);
}

KeySetLink float_config_table[] = {
  {"col", offsetof(KeyDict_float_config, col)},
  {"row", offsetof(KeyDict_float_config, row)},
  {"win", offsetof(KeyDict_float_config, win)},
  {"style", offsetof(KeyDict_float_config, style)},
  {"title", offsetof(KeyDict_float_config, title)},
  {"width", offsetof(KeyDict_float_config, width)},
  {"height", offsetof(KeyDict_float_config, height)},
  {"zindex", offsetof(KeyDict_float_config, zindex)},
  {"anchor", offsetof(KeyDict_float_config, anchor)},
  {"border", offsetof(KeyDict_float_config, border)},
  {"bufpos", offsetof(KeyDict_float_config, bufpos)},
  {"external", offsetof(KeyDict_float_config, external)},
  {"relative", offsetof(KeyDict_float_config, relative)},
  {"focusable", offsetof(KeyDict_float_config, focusable)},
  {"noautocmd", offsetof(KeyDict_float_config, noautocmd)},
  {"title_pos", offsetof(KeyDict_float_config, title_pos)},
  {NULL, 0},
};

int float_config_hash(const char *str, size_t len)
{
  int low = -1;
  switch (len) {
    case 3: switch (str[0]) {
      case 'c': low = 0; break;
      case 'r': low = 1; break;
      case 'w': low = 2; break;
      default: break;
    }
    break;
    case 5: switch (str[0]) {
      case 's': low = 3; break;
      case 't': low = 4; break;
      case 'w': low = 5; break;
      default: break;
    }
    break;
    case 6: switch (str[1]) {
      case 'e': low = 6; break;
      case 'i': low = 7; break;
      case 'n': low = 8; break;
      case 'o': low = 9; break;
      case 'u': low = 10; break;
      default: break;
    }
    break;
    case 8: switch (str[0]) {
      case 'e': low = 11; break;
      case 'r': low = 12; break;
      default: break;
    }
    break;
    case 9: switch (str[0]) {
      case 'f': low = 13; break;
      case 'n': low = 14; break;
      case 't': low = 15; break;
      default: break;
    }
    break;
    default: break;
  }
  if (low < 0 || memcmp(str, float_config_table[low].str, len)) {
    return -1;
  }
  return low;
}

Object *KeyDict_float_config_get_field(void *retval, const char *str, size_t len)
{
  int hash = float_config_hash(str, len);
  if (hash == -1) {
    return NULL;
  }

  return (Object *)((char *)retval + float_config_table[hash].ptr_off);
}

KeySetLink context_table[] = {
  {"types", offsetof(KeyDict_context, types)},
  {NULL, 0},
};

int context_hash(const char *str, size_t len)
{
  int low = -1;
  switch (len) {
    case 5: low = 0; break;
    default: break;
  }
  if (low < 0 || memcmp(str, context_table[low].str, len)) {
    return -1;
  }
  return low;
}

Object *KeyDict_context_get_field(void *retval, const char *str, size_t len)
{
  int hash = context_hash(str, len);
  if (hash == -1) {
    return NULL;
  }

  return (Object *)((char *)retval + context_table[hash].ptr_off);
}

KeySetLink set_decoration_provider_table[] = {
  {"on_buf", offsetof(KeyDict_set_decoration_provider, on_buf)},
  {"on_end", offsetof(KeyDict_set_decoration_provider, on_end)},
  {"on_win", offsetof(KeyDict_set_decoration_provider, on_win)},
  {"on_line", offsetof(KeyDict_set_decoration_provider, on_line)},
  {"on_start", offsetof(KeyDict_set_decoration_provider, on_start)},
  {"_on_hl_def", offsetof(KeyDict_set_decoration_provider, _on_hl_def)},
  {"_on_spell_nav", offsetof(KeyDict_set_decoration_provider, _on_spell_nav)},
  {NULL, 0},
};

int set_decoration_provider_hash(const char *str, size_t len)
{
  int low = -1;
  switch (len) {
    case 6: switch (str[3]) {
      case 'b': low = 0; break;
      case 'e': low = 1; break;
      case 'w': low = 2; break;
      default: break;
    }
    break;
    case 7: low = 3; break;
    case 8: low = 4; break;
    case 10: low = 5; break;
    case 13: low = 6; break;
    default: break;
  }
  if (low < 0 || memcmp(str, set_decoration_provider_table[low].str, len)) {
    return -1;
  }
  return low;
}

Object *KeyDict_set_decoration_provider_get_field(void *retval, const char *str, size_t len)
{
  int hash = set_decoration_provider_hash(str, len);
  if (hash == -1) {
    return NULL;
  }

  return (Object *)((char *)retval + set_decoration_provider_table[hash].ptr_off);
}

KeySetLink exec_autocmds_table[] = {
  {"data", offsetof(KeyDict_exec_autocmds, data)},
  {"group", offsetof(KeyDict_exec_autocmds, group)},
  {"buffer", offsetof(KeyDict_exec_autocmds, buffer)},
  {"pattern", offsetof(KeyDict_exec_autocmds, pattern)},
  {"modeline", offsetof(KeyDict_exec_autocmds, modeline)},
  {NULL, 0},
};

int exec_autocmds_hash(const char *str, size_t len)
{
  int low = -1;
  switch (len) {
    case 4: low = 0; break;
    case 5: low = 1; break;
    case 6: low = 2; break;
    case 7: low = 3; break;
    case 8: low = 4; break;
    default: break;
  }
  if (low < 0 || memcmp(str, exec_autocmds_table[low].str, len)) {
    return -1;
  }
  return low;
}

Object *KeyDict_exec_autocmds_get_field(void *retval, const char *str, size_t len)
{
  int hash = exec_autocmds_hash(str, len);
  if (hash == -1) {
    return NULL;
  }

  return (Object *)((char *)retval + exec_autocmds_table[hash].ptr_off);
}

KeySetLink get_autocmds_table[] = {
  {"event", offsetof(KeyDict_get_autocmds, event)},
  {"group", offsetof(KeyDict_get_autocmds, group)},
  {"buffer", offsetof(KeyDict_get_autocmds, buffer)},
  {"pattern", offsetof(KeyDict_get_autocmds, pattern)},
  {NULL, 0},
};

int get_autocmds_hash(const char *str, size_t len)
{
  int low = -1;
  switch (len) {
    case 5: switch (str[0]) {
      case 'e': low = 0; break;
      case 'g': low = 1; break;
      default: break;
    }
    break;
    case 6: low = 2; break;
    case 7: low = 3; break;
    default: break;
  }
  if (low < 0 || memcmp(str, get_autocmds_table[low].str, len)) {
    return -1;
  }
  return low;
}

Object *KeyDict_get_autocmds_get_field(void *retval, const char *str, size_t len)
{
  int hash = get_autocmds_hash(str, len);
  if (hash == -1) {
    return NULL;
  }

  return (Object *)((char *)retval + get_autocmds_table[hash].ptr_off);
}

KeySetLink create_augroup_table[] = {
  {"clear", offsetof(KeyDict_create_augroup, clear)},
  {NULL, 0},
};

int create_augroup_hash(const char *str, size_t len)
{
  int low = -1;
  switch (len) {
    case 5: low = 0; break;
    default: break;
  }
  if (low < 0 || memcmp(str, create_augroup_table[low].str, len)) {
    return -1;
  }
  return low;
}

Object *KeyDict_create_augroup_get_field(void *retval, const char *str, size_t len)
{
  int hash = create_augroup_hash(str, len);
  if (hash == -1) {
    return NULL;
  }

  return (Object *)((char *)retval + create_augroup_table[hash].ptr_off);
}

KeySetLink cmd_opts_table[] = {
  {"output", offsetof(KeyDict_cmd_opts, output)},
  {NULL, 0},
};

int cmd_opts_hash(const char *str, size_t len)
{
  int low = -1;
  switch (len) {
    case 6: low = 0; break;
    default: break;
  }
  if (low < 0 || memcmp(str, cmd_opts_table[low].str, len)) {
    return -1;
  }
  return low;
}

Object *KeyDict_cmd_opts_get_field(void *retval, const char *str, size_t len)
{
  int hash = cmd_opts_hash(str, len);
  if (hash == -1) {
    return NULL;
  }

  return (Object *)((char *)retval + cmd_opts_table[hash].ptr_off);
}

KeySetLink cmd_table[] = {
  {"cmd", offsetof(KeyDict_cmd, cmd)},
  {"reg", offsetof(KeyDict_cmd, reg)},
  {"bang", offsetof(KeyDict_cmd, bang)},
  {"addr", offsetof(KeyDict_cmd, addr)},
  {"mods", offsetof(KeyDict_cmd, mods)},
  {"args", offsetof(KeyDict_cmd, args)},
  {"count", offsetof(KeyDict_cmd, count)},
  {"magic", offsetof(KeyDict_cmd, magic)},
  {"nargs", offsetof(KeyDict_cmd, nargs)},
  {"range", offsetof(KeyDict_cmd, range)},
  {"nextcmd", offsetof(KeyDict_cmd, nextcmd)},
  {NULL, 0},
};

int cmd_hash(const char *str, size_t len)
{
  int low = -1;
  switch (len) {
    case 3: switch (str[0]) {
      case 'c': low = 0; break;
      case 'r': low = 1; break;
      default: break;
    }
    break;
    case 4: switch (str[1]) {
      case 'a': low = 2; break;
      case 'd': low = 3; break;
      case 'o': low = 4; break;
      case 'r': low = 5; break;
      default: break;
    }
    break;
    case 5: switch (str[0]) {
      case 'c': low = 6; break;
      case 'm': low = 7; break;
      case 'n': low = 8; break;
      case 'r': low = 9; break;
      default: break;
    }
    break;
    case 7: low = 10; break;
    default: break;
  }
  if (low < 0 || memcmp(str, cmd_table[low].str, len)) {
    return -1;
  }
  return low;
}

Object *KeyDict_cmd_get_field(void *retval, const char *str, size_t len)
{
  int hash = cmd_hash(str, len);
  if (hash == -1) {
    return NULL;
  }

  return (Object *)((char *)retval + cmd_table[hash].ptr_off);
}

KeySetLink set_extmark_table[] = {
  {"id", offsetof(KeyDict_set_extmark, id)},
  {"spell", offsetof(KeyDict_set_extmark, spell)},
  {"hl_eol", offsetof(KeyDict_set_extmark, hl_eol)},
  {"strict", offsetof(KeyDict_set_extmark, strict)},
  {"end_col", offsetof(KeyDict_set_extmark, end_col)},
  {"conceal", offsetof(KeyDict_set_extmark, conceal)},
  {"hl_mode", offsetof(KeyDict_set_extmark, hl_mode)},
  {"end_row", offsetof(KeyDict_set_extmark, end_row)},
  {"end_line", offsetof(KeyDict_set_extmark, end_line)},
  {"hl_group", offsetof(KeyDict_set_extmark, hl_group)},
  {"priority", offsetof(KeyDict_set_extmark, priority)},
  {"ephemeral", offsetof(KeyDict_set_extmark, ephemeral)},
  {"sign_text", offsetof(KeyDict_set_extmark, sign_text)},
  {"virt_text", offsetof(KeyDict_set_extmark, virt_text)},
  {"ui_watched", offsetof(KeyDict_set_extmark, ui_watched)},
  {"virt_lines", offsetof(KeyDict_set_extmark, virt_lines)},
  {"line_hl_group", offsetof(KeyDict_set_extmark, line_hl_group)},
  {"right_gravity", offsetof(KeyDict_set_extmark, right_gravity)},
  {"sign_hl_group", offsetof(KeyDict_set_extmark, sign_hl_group)},
  {"virt_text_pos", offsetof(KeyDict_set_extmark, virt_text_pos)},
  {"virt_text_hide", offsetof(KeyDict_set_extmark, virt_text_hide)},
  {"number_hl_group", offsetof(KeyDict_set_extmark, number_hl_group)},
  {"virt_lines_above", offsetof(KeyDict_set_extmark, virt_lines_above)},
  {"end_right_gravity", offsetof(KeyDict_set_extmark, end_right_gravity)},
  {"virt_text_win_col", offsetof(KeyDict_set_extmark, virt_text_win_col)},
  {"virt_lines_leftcol", offsetof(KeyDict_set_extmark, virt_lines_leftcol)},
  {"cursorline_hl_group", offsetof(KeyDict_set_extmark, cursorline_hl_group)},
  {NULL, 0},
};

int set_extmark_hash(const char *str, size_t len)
{
  int low = -1;
  switch (len) {
    case 2: low = 0; break;
    case 5: low = 1; break;
    case 6: switch (str[0]) {
      case 'h': low = 2; break;
      case 's': low = 3; break;
      default: break;
    }
    break;
    case 7: switch (str[4]) {
      case 'c': low = 4; break;
      case 'e': low = 5; break;
      case 'o': low = 6; break;
      case 'r': low = 7; break;
      default: break;
    }
    break;
    case 8: switch (str[0]) {
      case 'e': low = 8; break;
      case 'h': low = 9; break;
      case 'p': low = 10; break;
      default: break;
    }
    break;
    case 9: switch (str[0]) {
      case 'e': low = 11; break;
      case 's': low = 12; break;
      case 'v': low = 13; break;
      default: break;
    }
    break;
    case 10: switch (str[0]) {
      case 'u': low = 14; break;
      case 'v': low = 15; break;
      default: break;
    }
    break;
    case 13: switch (str[0]) {
      case 'l': low = 16; break;
      case 'r': low = 17; break;
      case 's': low = 18; break;
      case 'v': low = 19; break;
      default: break;
    }
    break;
    case 14: low = 20; break;
    case 15: low = 21; break;
    case 16: low = 22; break;
    case 17: switch (str[0]) {
      case 'e': low = 23; break;
      case 'v': low = 24; break;
      default: break;
    }
    break;
    case 18: low = 25; break;
    case 19: low = 26; break;
    default: break;
  }
  if (low < 0 || memcmp(str, set_extmark_table[low].str, len)) {
    return -1;
  }
  return low;
}

Object *KeyDict_set_extmark_get_field(void *retval, const char *str, size_t len)
{
  int hash = set_extmark_hash(str, len);
  if (hash == -1) {
    return NULL;
  }

  return (Object *)((char *)retval + set_extmark_table[hash].ptr_off);
}

KeySetLink cmd_mods_filter_table[] = {
  {"force", offsetof(KeyDict_cmd_mods_filter, force)},
  {"pattern", offsetof(KeyDict_cmd_mods_filter, pattern)},
  {NULL, 0},
};

int cmd_mods_filter_hash(const char *str, size_t len)
{
  int low = -1;
  switch (len) {
    case 5: low = 0; break;
    case 7: low = 1; break;
    default: break;
  }
  if (low < 0 || memcmp(str, cmd_mods_filter_table[low].str, len)) {
    return -1;
  }
  return low;
}

Object *KeyDict_cmd_mods_filter_get_field(void *retval, const char *str, size_t len)
{
  int hash = cmd_mods_filter_hash(str, len);
  if (hash == -1) {
    return NULL;
  }

  return (Object *)((char *)retval + cmd_mods_filter_table[hash].ptr_off);
}

KeySetLink get_commands_table[] = {
  {"builtin", offsetof(KeyDict_get_commands, builtin)},
  {NULL, 0},
};

int get_commands_hash(const char *str, size_t len)
{
  int low = -1;
  switch (len) {
    case 7: low = 0; break;
    default: break;
  }
  if (low < 0 || memcmp(str, get_commands_table[low].str, len)) {
    return -1;
  }
  return low;
}

Object *KeyDict_get_commands_get_field(void *retval, const char *str, size_t len)
{
  int hash = get_commands_hash(str, len);
  if (hash == -1) {
    return NULL;
  }

  return (Object *)((char *)retval + get_commands_table[hash].ptr_off);
}

KeySetLink runtime_table[] = {
  {"is_lua", offsetof(KeyDict_runtime, is_lua)},
  {"do_source", offsetof(KeyDict_runtime, do_source)},
  {NULL, 0},
};

int runtime_hash(const char *str, size_t len)
{
  int low = -1;
  switch (len) {
    case 6: low = 0; break;
    case 9: low = 1; break;
    default: break;
  }
  if (low < 0 || memcmp(str, runtime_table[low].str, len)) {
    return -1;
  }
  return low;
}

Object *KeyDict_runtime_get_field(void *retval, const char *str, size_t len)
{
  int hash = runtime_hash(str, len);
  if (hash == -1) {
    return NULL;
  }

  return (Object *)((char *)retval + runtime_table[hash].ptr_off);
}

KeySetLink user_command_table[] = {
  {"bar", offsetof(KeyDict_user_command, bar)},
  {"addr", offsetof(KeyDict_user_command, addr)},
  {"bang", offsetof(KeyDict_user_command, bang)},
  {"desc", offsetof(KeyDict_user_command, desc)},
  {"count", offsetof(KeyDict_user_command, count)},
  {"force", offsetof(KeyDict_user_command, force)},
  {"nargs", offsetof(KeyDict_user_command, nargs)},
  {"range", offsetof(KeyDict_user_command, range)},
  {"preview", offsetof(KeyDict_user_command, preview)},
  {"complete", offsetof(KeyDict_user_command, complete)},
  {"register", offsetof(KeyDict_user_command, register_)},
  {"keepscript", offsetof(KeyDict_user_command, keepscript)},
  {NULL, 0},
};

int user_command_hash(const char *str, size_t len)
{
  int low = -1;
  switch (len) {
    case 3: low = 0; break;
    case 4: switch (str[0]) {
      case 'a': low = 1; break;
      case 'b': low = 2; break;
      case 'd': low = 3; break;
      default: break;
    }
    break;
    case 5: switch (str[0]) {
      case 'c': low = 4; break;
      case 'f': low = 5; break;
      case 'n': low = 6; break;
      case 'r': low = 7; break;
      default: break;
    }
    break;
    case 7: low = 8; break;
    case 8: switch (str[0]) {
      case 'c': low = 9; break;
      case 'r': low = 10; break;
      default: break;
    }
    break;
    case 10: low = 11; break;
    default: break;
  }
  if (low < 0 || memcmp(str, user_command_table[low].str, len)) {
    return -1;
  }
  return low;
}

Object *KeyDict_user_command_get_field(void *retval, const char *str, size_t len)
{
  int hash = user_command_hash(str, len);
  if (hash == -1) {
    return NULL;
  }

  return (Object *)((char *)retval + user_command_table[hash].ptr_off);
}

KeySetLink cmd_magic_table[] = {
  {"bar", offsetof(KeyDict_cmd_magic, bar)},
  {"file", offsetof(KeyDict_cmd_magic, file)},
  {NULL, 0},
};

int cmd_magic_hash(const char *str, size_t len)
{
  int low = -1;
  switch (len) {
    case 3: low = 0; break;
    case 4: low = 1; break;
    default: break;
  }
  if (low < 0 || memcmp(str, cmd_magic_table[low].str, len)) {
    return -1;
  }
  return low;
}

Object *KeyDict_cmd_magic_get_field(void *retval, const char *str, size_t len)
{
  int hash = cmd_magic_hash(str, len);
  if (hash == -1) {
    return NULL;
  }

  return (Object *)((char *)retval + cmd_magic_table[hash].ptr_off);
}

KeySetLink eval_statusline_table[] = {
  {"winid", offsetof(KeyDict_eval_statusline, winid)},
  {"fillchar", offsetof(KeyDict_eval_statusline, fillchar)},
  {"maxwidth", offsetof(KeyDict_eval_statusline, maxwidth)},
  {"highlights", offsetof(KeyDict_eval_statusline, highlights)},
  {"use_winbar", offsetof(KeyDict_eval_statusline, use_winbar)},
  {"use_tabline", offsetof(KeyDict_eval_statusline, use_tabline)},
  {NULL, 0},
};

int eval_statusline_hash(const char *str, size_t len)
{
  int low = -1;
  switch (len) {
    case 5: low = 0; break;
    case 8: switch (str[0]) {
      case 'f': low = 1; break;
      case 'm': low = 2; break;
      default: break;
    }
    break;
    case 10: switch (str[0]) {
      case 'h': low = 3; break;
      case 'u': low = 4; break;
      default: break;
    }
    break;
    case 11: low = 5; break;
    default: break;
  }
  if (low < 0 || memcmp(str, eval_statusline_table[low].str, len)) {
    return -1;
  }
  return low;
}

Object *KeyDict_eval_statusline_get_field(void *retval, const char *str, size_t len)
{
  int hash = eval_statusline_hash(str, len);
  if (hash == -1) {
    return NULL;
  }

  return (Object *)((char *)retval + eval_statusline_table[hash].ptr_off);
}

KeySetLink cmd_mods_table[] = {
  {"tab", offsetof(KeyDict_cmd_mods, tab)},
  {"hide", offsetof(KeyDict_cmd_mods, hide)},
  {"split", offsetof(KeyDict_cmd_mods, split)},
  {"browse", offsetof(KeyDict_cmd_mods, browse)},
  {"filter", offsetof(KeyDict_cmd_mods, filter)},
  {"silent", offsetof(KeyDict_cmd_mods, silent)},
  {"confirm", offsetof(KeyDict_cmd_mods, confirm)},
  {"keepalt", offsetof(KeyDict_cmd_mods, keepalt)},
  {"sandbox", offsetof(KeyDict_cmd_mods, sandbox)},
  {"verbose", offsetof(KeyDict_cmd_mods, verbose)},
  {"unsilent", offsetof(KeyDict_cmd_mods, unsilent)},
  {"vertical", offsetof(KeyDict_cmd_mods, vertical)},
  {"keepjumps", offsetof(KeyDict_cmd_mods, keepjumps)},
  {"keepmarks", offsetof(KeyDict_cmd_mods, keepmarks)},
  {"lockmarks", offsetof(KeyDict_cmd_mods, lockmarks)},
  {"noautocmd", offsetof(KeyDict_cmd_mods, noautocmd)},
  {"horizontal", offsetof(KeyDict_cmd_mods, horizontal)},
  {"noswapfile", offsetof(KeyDict_cmd_mods, noswapfile)},
  {"emsg_silent", offsetof(KeyDict_cmd_mods, emsg_silent)},
  {"keeppatterns", offsetof(KeyDict_cmd_mods, keeppatterns)},
  {NULL, 0},
};

int cmd_mods_hash(const char *str, size_t len)
{
  int low = 0, high = 0;
  switch (len) {
    case 3: low = 0; high = 1; break;
    case 4: low = 1; high = 2; break;
    case 5: low = 2; high = 3; break;
    case 6: switch (str[0]) {
      case 'b': low = 3; high = 4; break;
      case 'f': low = 4; high = 5; break;
      case 's': low = 5; high = 6; break;
      default: break;
    }
    break;
    case 7: switch (str[0]) {
      case 'c': low = 6; high = 7; break;
      case 'k': low = 7; high = 8; break;
      case 's': low = 8; high = 9; break;
      case 'v': low = 9; high = 10; break;
      default: break;
    }
    break;
    case 8: switch (str[0]) {
      case 'u': low = 10; high = 11; break;
      case 'v': low = 11; high = 12; break;
      default: break;
    }
    break;
    case 9: switch (str[0]) {
      case 'k': low = 12; high = 14; break;
      case 'l': low = 14; high = 15; break;
      case 'n': low = 15; high = 16; break;
      default: break;
    }
    break;
    case 10: switch (str[0]) {
      case 'h': low = 16; high = 17; break;
      case 'n': low = 17; high = 18; break;
      default: break;
    }
    break;
    case 11: low = 18; high = 19; break;
    case 12: low = 19; high = 20; break;
    default: break;
  }
  for (int i = low; i < high; i++) {
    if (!memcmp(str, cmd_mods_table[i].str, len)) {
      return i;
    }
  }
  return -1;
}

Object *KeyDict_cmd_mods_get_field(void *retval, const char *str, size_t len)
{
  int hash = cmd_mods_hash(str, len);
  if (hash == -1) {
    return NULL;
  }

  return (Object *)((char *)retval + cmd_mods_table[hash].ptr_off);
}

KeySetLink highlight_cterm_table[] = {
  {"bold", offsetof(KeyDict_highlight_cterm, bold)},
  {"italic", offsetof(KeyDict_highlight_cterm, italic)},
  {"reverse", offsetof(KeyDict_highlight_cterm, reverse)},
  {"standout", offsetof(KeyDict_highlight_cterm, standout)},
  {"nocombine", offsetof(KeyDict_highlight_cterm, nocombine)},
  {"undercurl", offsetof(KeyDict_highlight_cterm, undercurl)},
  {"underline", offsetof(KeyDict_highlight_cterm, underline)},
  {"underdashed", offsetof(KeyDict_highlight_cterm, underdashed)},
  {"underdotted", offsetof(KeyDict_highlight_cterm, underdotted)},
  {"underdouble", offsetof(KeyDict_highlight_cterm, underdouble)},
  {"strikethrough", offsetof(KeyDict_highlight_cterm, strikethrough)},
  {NULL, 0},
};

int highlight_cterm_hash(const char *str, size_t len)
{
  int low = -1;
  switch (len) {
    case 4: low = 0; break;
    case 6: low = 1; break;
    case 7: low = 2; break;
    case 8: low = 3; break;
    case 9: switch (str[5]) {
      case 'b': low = 4; break;
      case 'c': low = 5; break;
      case 'l': low = 6; break;
      default: break;
    }
    break;
    case 11: switch (str[7]) {
      case 's': low = 7; break;
      case 't': low = 8; break;
      case 'u': low = 9; break;
      default: break;
    }
    break;
    case 13: low = 10; break;
    default: break;
  }
  if (low < 0 || memcmp(str, highlight_cterm_table[low].str, len)) {
    return -1;
  }
  return low;
}

Object *KeyDict_highlight_cterm_get_field(void *retval, const char *str, size_t len)
{
  int hash = highlight_cterm_hash(str, len);
  if (hash == -1) {
    return NULL;
  }

  return (Object *)((char *)retval + highlight_cterm_table[hash].ptr_off);
}

KeySetLink clear_autocmds_table[] = {
  {"event", offsetof(KeyDict_clear_autocmds, event)},
  {"group", offsetof(KeyDict_clear_autocmds, group)},
  {"buffer", offsetof(KeyDict_clear_autocmds, buffer)},
  {"pattern", offsetof(KeyDict_clear_autocmds, pattern)},
  {NULL, 0},
};

int clear_autocmds_hash(const char *str, size_t len)
{
  int low = -1;
  switch (len) {
    case 5: switch (str[0]) {
      case 'e': low = 0; break;
      case 'g': low = 1; break;
      default: break;
    }
    break;
    case 6: low = 2; break;
    case 7: low = 3; break;
    default: break;
  }
  if (low < 0 || memcmp(str, clear_autocmds_table[low].str, len)) {
    return -1;
  }
  return low;
}

Object *KeyDict_clear_autocmds_get_field(void *retval, const char *str, size_t len)
{
  int hash = clear_autocmds_hash(str, len);
  if (hash == -1) {
    return NULL;
  }

  return (Object *)((char *)retval + clear_autocmds_table[hash].ptr_off);
}

KeySetLink keymap_table[] = {
  {"desc", offsetof(KeyDict_keymap, desc)},
  {"expr", offsetof(KeyDict_keymap, expr)},
  {"script", offsetof(KeyDict_keymap, script)},
  {"silent", offsetof(KeyDict_keymap, silent)},
  {"unique", offsetof(KeyDict_keymap, unique)},
  {"nowait", offsetof(KeyDict_keymap, nowait)},
  {"noremap", offsetof(KeyDict_keymap, noremap)},
  {"callback", offsetof(KeyDict_keymap, callback)},
  {"replace_keycodes", offsetof(KeyDict_keymap, replace_keycodes)},
  {NULL, 0},
};

int keymap_hash(const char *str, size_t len)
{
  int low = -1;
  switch (len) {
    case 4: switch (str[0]) {
      case 'd': low = 0; break;
      case 'e': low = 1; break;
      default: break;
    }
    break;
    case 6: switch (str[1]) {
      case 'c': low = 2; break;
      case 'i': low = 3; break;
      case 'n': low = 4; break;
      case 'o': low = 5; break;
      default: break;
    }
    break;
    case 7: low = 6; break;
    case 8: low = 7; break;
    case 16: low = 8; break;
    default: break;
  }
  if (low < 0 || memcmp(str, keymap_table[low].str, len)) {
    return -1;
  }
  return low;
}

Object *KeyDict_keymap_get_field(void *retval, const char *str, size_t len)
{
  int hash = keymap_hash(str, len);
  if (hash == -1) {
    return NULL;
  }

  return (Object *)((char *)retval + keymap_table[hash].ptr_off);
}

