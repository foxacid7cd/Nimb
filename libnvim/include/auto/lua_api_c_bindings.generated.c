// This is an open source non-commercial project. Dear PVS-Studio, please check
// it. PVS-Studio Static Code Analyzer for C, C++ and C#: http://www.viva64.com
#include <lua.h>
#include <lualib.h>
#include <lauxlib.h>

#include "nvim/func_attr.h"
#include "nvim/api/private/defs.h"
#include "nvim/api/private/helpers.h"
#include "nvim/lua/converter.h"
#include "nvim/lua/executor.h"
#include "nvim/memory.h"


#include "nvim/api/autocmd.h"
#include "nvim/api/buffer.h"
#include "nvim/api/command.h"
#include "nvim/api/deprecated.h"
#include "nvim/api/extmark.h"
#include "nvim/api/options.h"
#include "nvim/api/tabpage.h"
#include "nvim/api/ui.h"
#include "nvim/api/vim.h"
#include "nvim/api/vimscript.h"
#include "nvim/api/win_config.h"
#include "nvim/api/window.h"

static int nlua_api_nvim_get_autocmds(lua_State *lstate)
{
  Error err = ERROR_INIT;
  if (lua_gettop(lstate) != 1) {
    api_set_error(&err, kErrorTypeValidation, "Expected 1 argument");
    goto exit_0;
  }
  if (!nlua_is_deferred_safe()) {
    return luaL_error(lstate, e_luv_api_disabled, "nvim_get_autocmds");
  }
    KeyDict_get_autocmds arg1 = { 0 }; nlua_pop_keydict(lstate, &arg1, KeyDict_get_autocmds_get_field, &err);
  if (ERROR_SET(&err)) {
    goto exit_1;
  }

  const Array ret = nvim_get_autocmds(&arg1, &err);
  nlua_push_Array(lstate, ret, true);
api_free_array(ret);

exit_1:
  api_free_keydict_get_autocmds(&arg1);

exit_0:
  if (ERROR_SET(&err)) {
    luaL_where(lstate, 1);
    lua_pushstring(lstate, err.msg);
    api_clear_error(&err);
    lua_concat(lstate, 2);
    return lua_error(lstate);
  }

  return 1;
}

static int nlua_api_nvim_create_autocmd(lua_State *lstate)
{
  Error err = ERROR_INIT;
  if (lua_gettop(lstate) != 2) {
    api_set_error(&err, kErrorTypeValidation, "Expected 2 arguments");
    goto exit_0;
  }
  if (!nlua_is_deferred_safe()) {
    return luaL_error(lstate, e_luv_api_disabled, "nvim_create_autocmd");
  }
    KeyDict_create_autocmd arg2 = { 0 }; nlua_pop_keydict(lstate, &arg2, KeyDict_create_autocmd_get_field, &err);
  if (ERROR_SET(&err)) {
    goto exit_1;
  }

    const Object arg1 = nlua_pop_Object(lstate, true, &err);
  if (ERROR_SET(&err)) {
    goto exit_1;
  }

  const Integer ret = nvim_create_autocmd(LUA_INTERNAL_CALL, arg1, &arg2, &err);
  nlua_push_Integer(lstate, ret, true);
api_free_integer(ret);

  api_free_object(arg1);
exit_1:
  api_free_keydict_create_autocmd(&arg2);

exit_0:
  if (ERROR_SET(&err)) {
    luaL_where(lstate, 1);
    lua_pushstring(lstate, err.msg);
    api_clear_error(&err);
    lua_concat(lstate, 2);
    return lua_error(lstate);
  }

  return 1;
}

static int nlua_api_nvim_del_autocmd(lua_State *lstate)
{
  Error err = ERROR_INIT;
  if (lua_gettop(lstate) != 1) {
    api_set_error(&err, kErrorTypeValidation, "Expected 1 argument");
    goto exit_0;
  }
  if (!nlua_is_deferred_safe()) {
    return luaL_error(lstate, e_luv_api_disabled, "nvim_del_autocmd");
  }
    const Integer arg1 = nlua_pop_Integer(lstate, &err);
  if (ERROR_SET(&err)) {
    goto exit_0;
  }

  nvim_del_autocmd(arg1, &err);

  api_free_integer(arg1);

exit_0:
  if (ERROR_SET(&err)) {
    luaL_where(lstate, 1);
    lua_pushstring(lstate, err.msg);
    api_clear_error(&err);
    lua_concat(lstate, 2);
    return lua_error(lstate);
  }

  return 0;
}

static int nlua_api_nvim_clear_autocmds(lua_State *lstate)
{
  Error err = ERROR_INIT;
  if (lua_gettop(lstate) != 1) {
    api_set_error(&err, kErrorTypeValidation, "Expected 1 argument");
    goto exit_0;
  }
  if (!nlua_is_deferred_safe()) {
    return luaL_error(lstate, e_luv_api_disabled, "nvim_clear_autocmds");
  }
    KeyDict_clear_autocmds arg1 = { 0 }; nlua_pop_keydict(lstate, &arg1, KeyDict_clear_autocmds_get_field, &err);
  if (ERROR_SET(&err)) {
    goto exit_1;
  }

  nvim_clear_autocmds(&arg1, &err);

exit_1:
  api_free_keydict_clear_autocmds(&arg1);

exit_0:
  if (ERROR_SET(&err)) {
    luaL_where(lstate, 1);
    lua_pushstring(lstate, err.msg);
    api_clear_error(&err);
    lua_concat(lstate, 2);
    return lua_error(lstate);
  }

  return 0;
}

static int nlua_api_nvim_create_augroup(lua_State *lstate)
{
  Error err = ERROR_INIT;
  if (lua_gettop(lstate) != 2) {
    api_set_error(&err, kErrorTypeValidation, "Expected 2 arguments");
    goto exit_0;
  }
  if (!nlua_is_deferred_safe()) {
    return luaL_error(lstate, e_luv_api_disabled, "nvim_create_augroup");
  }
    KeyDict_create_augroup arg2 = { 0 }; nlua_pop_keydict(lstate, &arg2, KeyDict_create_augroup_get_field, &err);
  if (ERROR_SET(&err)) {
    goto exit_1;
  }

    const String arg1 = nlua_pop_String(lstate, &err);
  if (ERROR_SET(&err)) {
    goto exit_1;
  }

  const Integer ret = nvim_create_augroup(LUA_INTERNAL_CALL, arg1, &arg2, &err);
  nlua_push_Integer(lstate, ret, true);
api_free_integer(ret);

  api_free_string(arg1);
exit_1:
  api_free_keydict_create_augroup(&arg2);

exit_0:
  if (ERROR_SET(&err)) {
    luaL_where(lstate, 1);
    lua_pushstring(lstate, err.msg);
    api_clear_error(&err);
    lua_concat(lstate, 2);
    return lua_error(lstate);
  }

  return 1;
}

static int nlua_api_nvim_del_augroup_by_id(lua_State *lstate)
{
  Error err = ERROR_INIT;
  if (lua_gettop(lstate) != 1) {
    api_set_error(&err, kErrorTypeValidation, "Expected 1 argument");
    goto exit_0;
  }
  if (!nlua_is_deferred_safe()) {
    return luaL_error(lstate, e_luv_api_disabled, "nvim_del_augroup_by_id");
  }
    const Integer arg1 = nlua_pop_Integer(lstate, &err);
  if (ERROR_SET(&err)) {
    goto exit_0;
  }

  nvim_del_augroup_by_id(arg1, &err);

  api_free_integer(arg1);

exit_0:
  if (ERROR_SET(&err)) {
    luaL_where(lstate, 1);
    lua_pushstring(lstate, err.msg);
    api_clear_error(&err);
    lua_concat(lstate, 2);
    return lua_error(lstate);
  }

  return 0;
}

static int nlua_api_nvim_del_augroup_by_name(lua_State *lstate)
{
  Error err = ERROR_INIT;
  if (lua_gettop(lstate) != 1) {
    api_set_error(&err, kErrorTypeValidation, "Expected 1 argument");
    goto exit_0;
  }
  if (!nlua_is_deferred_safe()) {
    return luaL_error(lstate, e_luv_api_disabled, "nvim_del_augroup_by_name");
  }
    const String arg1 = nlua_pop_String(lstate, &err);
  if (ERROR_SET(&err)) {
    goto exit_0;
  }

  nvim_del_augroup_by_name(arg1, &err);

  api_free_string(arg1);

exit_0:
  if (ERROR_SET(&err)) {
    luaL_where(lstate, 1);
    lua_pushstring(lstate, err.msg);
    api_clear_error(&err);
    lua_concat(lstate, 2);
    return lua_error(lstate);
  }

  return 0;
}

static int nlua_api_nvim_exec_autocmds(lua_State *lstate)
{
  Error err = ERROR_INIT;
  if (lua_gettop(lstate) != 2) {
    api_set_error(&err, kErrorTypeValidation, "Expected 2 arguments");
    goto exit_0;
  }
  if (!nlua_is_deferred_safe()) {
    return luaL_error(lstate, e_luv_api_disabled, "nvim_exec_autocmds");
  }
    KeyDict_exec_autocmds arg2 = { 0 }; nlua_pop_keydict(lstate, &arg2, KeyDict_exec_autocmds_get_field, &err);
  if (ERROR_SET(&err)) {
    goto exit_1;
  }

    const Object arg1 = nlua_pop_Object(lstate, true, &err);
  if (ERROR_SET(&err)) {
    goto exit_1;
  }

  nvim_exec_autocmds(arg1, &arg2, &err);

  api_free_object(arg1);
exit_1:
  api_free_keydict_exec_autocmds(&arg2);

exit_0:
  if (ERROR_SET(&err)) {
    luaL_where(lstate, 1);
    lua_pushstring(lstate, err.msg);
    api_clear_error(&err);
    lua_concat(lstate, 2);
    return lua_error(lstate);
  }

  return 0;
}

static int nlua_api_nvim_buf_line_count(lua_State *lstate)
{
  Error err = ERROR_INIT;
  if (lua_gettop(lstate) != 1) {
    api_set_error(&err, kErrorTypeValidation, "Expected 1 argument");
    goto exit_0;
  }
  if (!nlua_is_deferred_safe()) {
    return luaL_error(lstate, e_luv_api_disabled, "nvim_buf_line_count");
  }
    const Buffer arg1 = nlua_pop_Buffer(lstate, &err);
  if (ERROR_SET(&err)) {
    goto exit_0;
  }

  const Integer ret = nvim_buf_line_count(arg1, &err);
  nlua_push_Integer(lstate, ret, true);
api_free_integer(ret);

  api_free_buffer(arg1);

exit_0:
  if (ERROR_SET(&err)) {
    luaL_where(lstate, 1);
    lua_pushstring(lstate, err.msg);
    api_clear_error(&err);
    lua_concat(lstate, 2);
    return lua_error(lstate);
  }

  return 1;
}

static int nlua_api_nvim_buf_attach(lua_State *lstate)
{
  Error err = ERROR_INIT;
  if (lua_gettop(lstate) != 3) {
    api_set_error(&err, kErrorTypeValidation, "Expected 3 arguments");
    goto exit_0;
  }
  if (!nlua_is_deferred_safe()) {
    return luaL_error(lstate, e_luv_api_disabled, "nvim_buf_attach");
  }
    const DictionaryOf(LuaRef) arg3 = nlua_pop_Dictionary(lstate, true, &err);
  if (ERROR_SET(&err)) {
    goto exit_0;
  }

    const Boolean arg2 = nlua_pop_Boolean(lstate, &err);
  if (ERROR_SET(&err)) {
    goto exit_1;
  }

    const Buffer arg1 = nlua_pop_Buffer(lstate, &err);
  if (ERROR_SET(&err)) {
    goto exit_2;
  }

  const Boolean ret = nvim_buf_attach(LUA_INTERNAL_CALL, arg1, arg2, arg3, &err);
  nlua_push_Boolean(lstate, ret, true);
api_free_boolean(ret);

  api_free_buffer(arg1);
exit_2:
  api_free_boolean(arg2);
exit_1:
  api_free_dictionary(arg3);

exit_0:
  if (ERROR_SET(&err)) {
    luaL_where(lstate, 1);
    lua_pushstring(lstate, err.msg);
    api_clear_error(&err);
    lua_concat(lstate, 2);
    return lua_error(lstate);
  }

  return 1;
}

static int nlua_api_nvim__buf_redraw_range(lua_State *lstate)
{
  Error err = ERROR_INIT;
  if (lua_gettop(lstate) != 3) {
    api_set_error(&err, kErrorTypeValidation, "Expected 3 arguments");
    goto exit_0;
  }
  if (!nlua_is_deferred_safe()) {
    return luaL_error(lstate, e_luv_api_disabled, "nvim__buf_redraw_range");
  }
    const Integer arg3 = nlua_pop_Integer(lstate, &err);
  if (ERROR_SET(&err)) {
    goto exit_0;
  }

    const Integer arg2 = nlua_pop_Integer(lstate, &err);
  if (ERROR_SET(&err)) {
    goto exit_1;
  }

    const Buffer arg1 = nlua_pop_Buffer(lstate, &err);
  if (ERROR_SET(&err)) {
    goto exit_2;
  }

  nvim__buf_redraw_range(arg1, arg2, arg3, &err);

  api_free_buffer(arg1);
exit_2:
  api_free_integer(arg2);
exit_1:
  api_free_integer(arg3);

exit_0:
  if (ERROR_SET(&err)) {
    luaL_where(lstate, 1);
    lua_pushstring(lstate, err.msg);
    api_clear_error(&err);
    lua_concat(lstate, 2);
    return lua_error(lstate);
  }

  return 0;
}

static int nlua_api_nvim_buf_get_lines(lua_State *lstate)
{
  Error err = ERROR_INIT;
  if (lua_gettop(lstate) != 4) {
    api_set_error(&err, kErrorTypeValidation, "Expected 4 arguments");
    goto exit_0;
  }
  if (!nlua_is_deferred_safe()) {
    return luaL_error(lstate, e_luv_api_disabled, "nvim_buf_get_lines");
  }
    const Boolean arg4 = nlua_pop_Boolean(lstate, &err);
  if (ERROR_SET(&err)) {
    goto exit_0;
  }

    const Integer arg3 = nlua_pop_Integer(lstate, &err);
  if (ERROR_SET(&err)) {
    goto exit_1;
  }

    const Integer arg2 = nlua_pop_Integer(lstate, &err);
  if (ERROR_SET(&err)) {
    goto exit_2;
  }

    const Buffer arg1 = nlua_pop_Buffer(lstate, &err);
  if (ERROR_SET(&err)) {
    goto exit_3;
  }

  const ArrayOf(String) ret = nvim_buf_get_lines(LUA_INTERNAL_CALL, arg1, arg2, arg3, arg4, &err);
  nlua_push_Array(lstate, ret, true);
api_free_array(ret);

  api_free_buffer(arg1);
exit_3:
  api_free_integer(arg2);
exit_2:
  api_free_integer(arg3);
exit_1:
  api_free_boolean(arg4);

exit_0:
  if (ERROR_SET(&err)) {
    luaL_where(lstate, 1);
    lua_pushstring(lstate, err.msg);
    api_clear_error(&err);
    lua_concat(lstate, 2);
    return lua_error(lstate);
  }

  return 1;
}

static int nlua_api_nvim_buf_set_lines(lua_State *lstate)
{
  Error err = ERROR_INIT;
  if (lua_gettop(lstate) != 5) {
    api_set_error(&err, kErrorTypeValidation, "Expected 5 arguments");
    goto exit_0;
  }
  if (!nlua_is_deferred_safe()) {
    return luaL_error(lstate, e_luv_api_disabled, "nvim_buf_set_lines");
  }
  if (textlock != 0) {
    api_set_error(&err, kErrorTypeException, "%s", e_textlock);
    goto exit_0;
  }
    const ArrayOf(String) arg5 = nlua_pop_Array(lstate, &err);
  if (ERROR_SET(&err)) {
    goto exit_0;
  }

    const Boolean arg4 = nlua_pop_Boolean(lstate, &err);
  if (ERROR_SET(&err)) {
    goto exit_1;
  }

    const Integer arg3 = nlua_pop_Integer(lstate, &err);
  if (ERROR_SET(&err)) {
    goto exit_2;
  }

    const Integer arg2 = nlua_pop_Integer(lstate, &err);
  if (ERROR_SET(&err)) {
    goto exit_3;
  }

    const Buffer arg1 = nlua_pop_Buffer(lstate, &err);
  if (ERROR_SET(&err)) {
    goto exit_4;
  }

  nvim_buf_set_lines(LUA_INTERNAL_CALL, arg1, arg2, arg3, arg4, arg5, &err);

  api_free_buffer(arg1);
exit_4:
  api_free_integer(arg2);
exit_3:
  api_free_integer(arg3);
exit_2:
  api_free_boolean(arg4);
exit_1:
  api_free_array(arg5);

exit_0:
  if (ERROR_SET(&err)) {
    luaL_where(lstate, 1);
    lua_pushstring(lstate, err.msg);
    api_clear_error(&err);
    lua_concat(lstate, 2);
    return lua_error(lstate);
  }

  return 0;
}

static int nlua_api_nvim_buf_set_text(lua_State *lstate)
{
  Error err = ERROR_INIT;
  if (lua_gettop(lstate) != 6) {
    api_set_error(&err, kErrorTypeValidation, "Expected 6 arguments");
    goto exit_0;
  }
  if (!nlua_is_deferred_safe()) {
    return luaL_error(lstate, e_luv_api_disabled, "nvim_buf_set_text");
  }
    const ArrayOf(String) arg6 = nlua_pop_Array(lstate, &err);
  if (ERROR_SET(&err)) {
    goto exit_0;
  }

    const Integer arg5 = nlua_pop_Integer(lstate, &err);
  if (ERROR_SET(&err)) {
    goto exit_1;
  }

    const Integer arg4 = nlua_pop_Integer(lstate, &err);
  if (ERROR_SET(&err)) {
    goto exit_2;
  }

    const Integer arg3 = nlua_pop_Integer(lstate, &err);
  if (ERROR_SET(&err)) {
    goto exit_3;
  }

    const Integer arg2 = nlua_pop_Integer(lstate, &err);
  if (ERROR_SET(&err)) {
    goto exit_4;
  }

    const Buffer arg1 = nlua_pop_Buffer(lstate, &err);
  if (ERROR_SET(&err)) {
    goto exit_5;
  }

  nvim_buf_set_text(LUA_INTERNAL_CALL, arg1, arg2, arg3, arg4, arg5, arg6, &err);

  api_free_buffer(arg1);
exit_5:
  api_free_integer(arg2);
exit_4:
  api_free_integer(arg3);
exit_3:
  api_free_integer(arg4);
exit_2:
  api_free_integer(arg5);
exit_1:
  api_free_array(arg6);

exit_0:
  if (ERROR_SET(&err)) {
    luaL_where(lstate, 1);
    lua_pushstring(lstate, err.msg);
    api_clear_error(&err);
    lua_concat(lstate, 2);
    return lua_error(lstate);
  }

  return 0;
}

static int nlua_api_nvim_buf_get_text(lua_State *lstate)
{
  Error err = ERROR_INIT;
  if (lua_gettop(lstate) != 6) {
    api_set_error(&err, kErrorTypeValidation, "Expected 6 arguments");
    goto exit_0;
  }
  if (!nlua_is_deferred_safe()) {
    return luaL_error(lstate, e_luv_api_disabled, "nvim_buf_get_text");
  }
    const Dictionary arg6 = nlua_pop_Dictionary(lstate, false, &err);
  if (ERROR_SET(&err)) {
    goto exit_0;
  }

    const Integer arg5 = nlua_pop_Integer(lstate, &err);
  if (ERROR_SET(&err)) {
    goto exit_1;
  }

    const Integer arg4 = nlua_pop_Integer(lstate, &err);
  if (ERROR_SET(&err)) {
    goto exit_2;
  }

    const Integer arg3 = nlua_pop_Integer(lstate, &err);
  if (ERROR_SET(&err)) {
    goto exit_3;
  }

    const Integer arg2 = nlua_pop_Integer(lstate, &err);
  if (ERROR_SET(&err)) {
    goto exit_4;
  }

    const Buffer arg1 = nlua_pop_Buffer(lstate, &err);
  if (ERROR_SET(&err)) {
    goto exit_5;
  }

  const ArrayOf(String) ret = nvim_buf_get_text(LUA_INTERNAL_CALL, arg1, arg2, arg3, arg4, arg5, arg6, &err);
  nlua_push_Array(lstate, ret, true);
api_free_array(ret);

  api_free_buffer(arg1);
exit_5:
  api_free_integer(arg2);
exit_4:
  api_free_integer(arg3);
exit_3:
  api_free_integer(arg4);
exit_2:
  api_free_integer(arg5);
exit_1:
  api_free_dictionary(arg6);

exit_0:
  if (ERROR_SET(&err)) {
    luaL_where(lstate, 1);
    lua_pushstring(lstate, err.msg);
    api_clear_error(&err);
    lua_concat(lstate, 2);
    return lua_error(lstate);
  }

  return 1;
}

static int nlua_api_nvim_buf_get_offset(lua_State *lstate)
{
  Error err = ERROR_INIT;
  if (lua_gettop(lstate) != 2) {
    api_set_error(&err, kErrorTypeValidation, "Expected 2 arguments");
    goto exit_0;
  }
  if (!nlua_is_deferred_safe()) {
    return luaL_error(lstate, e_luv_api_disabled, "nvim_buf_get_offset");
  }
    const Integer arg2 = nlua_pop_Integer(lstate, &err);
  if (ERROR_SET(&err)) {
    goto exit_0;
  }

    const Buffer arg1 = nlua_pop_Buffer(lstate, &err);
  if (ERROR_SET(&err)) {
    goto exit_1;
  }

  const Integer ret = nvim_buf_get_offset(arg1, arg2, &err);
  nlua_push_Integer(lstate, ret, true);
api_free_integer(ret);

  api_free_buffer(arg1);
exit_1:
  api_free_integer(arg2);

exit_0:
  if (ERROR_SET(&err)) {
    luaL_where(lstate, 1);
    lua_pushstring(lstate, err.msg);
    api_clear_error(&err);
    lua_concat(lstate, 2);
    return lua_error(lstate);
  }

  return 1;
}

static int nlua_api_nvim_buf_get_var(lua_State *lstate)
{
  Error err = ERROR_INIT;
  if (lua_gettop(lstate) != 2) {
    api_set_error(&err, kErrorTypeValidation, "Expected 2 arguments");
    goto exit_0;
  }
  if (!nlua_is_deferred_safe()) {
    return luaL_error(lstate, e_luv_api_disabled, "nvim_buf_get_var");
  }
    const String arg2 = nlua_pop_String(lstate, &err);
  if (ERROR_SET(&err)) {
    goto exit_0;
  }

    const Buffer arg1 = nlua_pop_Buffer(lstate, &err);
  if (ERROR_SET(&err)) {
    goto exit_1;
  }

  const Object ret = nvim_buf_get_var(arg1, arg2, &err);
  nlua_push_Object(lstate, ret, true);
api_free_object(ret);

  api_free_buffer(arg1);
exit_1:
  api_free_string(arg2);

exit_0:
  if (ERROR_SET(&err)) {
    luaL_where(lstate, 1);
    lua_pushstring(lstate, err.msg);
    api_clear_error(&err);
    lua_concat(lstate, 2);
    return lua_error(lstate);
  }

  return 1;
}

static int nlua_api_nvim_buf_get_changedtick(lua_State *lstate)
{
  Error err = ERROR_INIT;
  if (lua_gettop(lstate) != 1) {
    api_set_error(&err, kErrorTypeValidation, "Expected 1 argument");
    goto exit_0;
  }
  if (!nlua_is_deferred_safe()) {
    return luaL_error(lstate, e_luv_api_disabled, "nvim_buf_get_changedtick");
  }
    const Buffer arg1 = nlua_pop_Buffer(lstate, &err);
  if (ERROR_SET(&err)) {
    goto exit_0;
  }

  const Integer ret = nvim_buf_get_changedtick(arg1, &err);
  nlua_push_Integer(lstate, ret, true);
api_free_integer(ret);

  api_free_buffer(arg1);

exit_0:
  if (ERROR_SET(&err)) {
    luaL_where(lstate, 1);
    lua_pushstring(lstate, err.msg);
    api_clear_error(&err);
    lua_concat(lstate, 2);
    return lua_error(lstate);
  }

  return 1;
}

static int nlua_api_nvim_buf_get_keymap(lua_State *lstate)
{
  Error err = ERROR_INIT;
  if (lua_gettop(lstate) != 2) {
    api_set_error(&err, kErrorTypeValidation, "Expected 2 arguments");
    goto exit_0;
  }
  if (!nlua_is_deferred_safe()) {
    return luaL_error(lstate, e_luv_api_disabled, "nvim_buf_get_keymap");
  }
    const String arg2 = nlua_pop_String(lstate, &err);
  if (ERROR_SET(&err)) {
    goto exit_0;
  }

    const Buffer arg1 = nlua_pop_Buffer(lstate, &err);
  if (ERROR_SET(&err)) {
    goto exit_1;
  }

  const ArrayOf(Dictionary) ret = nvim_buf_get_keymap(arg1, arg2, &err);
  nlua_push_Array(lstate, ret, true);
api_free_array(ret);

  api_free_buffer(arg1);
exit_1:
  api_free_string(arg2);

exit_0:
  if (ERROR_SET(&err)) {
    luaL_where(lstate, 1);
    lua_pushstring(lstate, err.msg);
    api_clear_error(&err);
    lua_concat(lstate, 2);
    return lua_error(lstate);
  }

  return 1;
}

static int nlua_api_nvim_buf_set_keymap(lua_State *lstate)
{
  Error err = ERROR_INIT;
  if (lua_gettop(lstate) != 5) {
    api_set_error(&err, kErrorTypeValidation, "Expected 5 arguments");
    goto exit_0;
  }
  if (!nlua_is_deferred_safe()) {
    return luaL_error(lstate, e_luv_api_disabled, "nvim_buf_set_keymap");
  }
    KeyDict_keymap arg5 = { 0 }; nlua_pop_keydict(lstate, &arg5, KeyDict_keymap_get_field, &err);
  if (ERROR_SET(&err)) {
    goto exit_1;
  }

    const String arg4 = nlua_pop_String(lstate, &err);
  if (ERROR_SET(&err)) {
    goto exit_1;
  }

    const String arg3 = nlua_pop_String(lstate, &err);
  if (ERROR_SET(&err)) {
    goto exit_2;
  }

    const String arg2 = nlua_pop_String(lstate, &err);
  if (ERROR_SET(&err)) {
    goto exit_3;
  }

    const Buffer arg1 = nlua_pop_Buffer(lstate, &err);
  if (ERROR_SET(&err)) {
    goto exit_4;
  }

  nvim_buf_set_keymap(LUA_INTERNAL_CALL, arg1, arg2, arg3, arg4, &arg5, &err);

  api_free_buffer(arg1);
exit_4:
  api_free_string(arg2);
exit_3:
  api_free_string(arg3);
exit_2:
  api_free_string(arg4);
exit_1:
  api_free_keydict_keymap(&arg5);

exit_0:
  if (ERROR_SET(&err)) {
    luaL_where(lstate, 1);
    lua_pushstring(lstate, err.msg);
    api_clear_error(&err);
    lua_concat(lstate, 2);
    return lua_error(lstate);
  }

  return 0;
}

static int nlua_api_nvim_buf_del_keymap(lua_State *lstate)
{
  Error err = ERROR_INIT;
  if (lua_gettop(lstate) != 3) {
    api_set_error(&err, kErrorTypeValidation, "Expected 3 arguments");
    goto exit_0;
  }
  if (!nlua_is_deferred_safe()) {
    return luaL_error(lstate, e_luv_api_disabled, "nvim_buf_del_keymap");
  }
    const String arg3 = nlua_pop_String(lstate, &err);
  if (ERROR_SET(&err)) {
    goto exit_0;
  }

    const String arg2 = nlua_pop_String(lstate, &err);
  if (ERROR_SET(&err)) {
    goto exit_1;
  }

    const Buffer arg1 = nlua_pop_Buffer(lstate, &err);
  if (ERROR_SET(&err)) {
    goto exit_2;
  }

  nvim_buf_del_keymap(LUA_INTERNAL_CALL, arg1, arg2, arg3, &err);

  api_free_buffer(arg1);
exit_2:
  api_free_string(arg2);
exit_1:
  api_free_string(arg3);

exit_0:
  if (ERROR_SET(&err)) {
    luaL_where(lstate, 1);
    lua_pushstring(lstate, err.msg);
    api_clear_error(&err);
    lua_concat(lstate, 2);
    return lua_error(lstate);
  }

  return 0;
}

static int nlua_api_nvim_buf_set_var(lua_State *lstate)
{
  Error err = ERROR_INIT;
  if (lua_gettop(lstate) != 3) {
    api_set_error(&err, kErrorTypeValidation, "Expected 3 arguments");
    goto exit_0;
  }
  if (!nlua_is_deferred_safe()) {
    return luaL_error(lstate, e_luv_api_disabled, "nvim_buf_set_var");
  }
    const Object arg3 = nlua_pop_Object(lstate, true, &err);
  if (ERROR_SET(&err)) {
    goto exit_0;
  }

    const String arg2 = nlua_pop_String(lstate, &err);
  if (ERROR_SET(&err)) {
    goto exit_1;
  }

    const Buffer arg1 = nlua_pop_Buffer(lstate, &err);
  if (ERROR_SET(&err)) {
    goto exit_2;
  }

  nvim_buf_set_var(arg1, arg2, arg3, &err);

  api_free_buffer(arg1);
exit_2:
  api_free_string(arg2);
exit_1:
  api_free_object(arg3);

exit_0:
  if (ERROR_SET(&err)) {
    luaL_where(lstate, 1);
    lua_pushstring(lstate, err.msg);
    api_clear_error(&err);
    lua_concat(lstate, 2);
    return lua_error(lstate);
  }

  return 0;
}

static int nlua_api_nvim_buf_del_var(lua_State *lstate)
{
  Error err = ERROR_INIT;
  if (lua_gettop(lstate) != 2) {
    api_set_error(&err, kErrorTypeValidation, "Expected 2 arguments");
    goto exit_0;
  }
  if (!nlua_is_deferred_safe()) {
    return luaL_error(lstate, e_luv_api_disabled, "nvim_buf_del_var");
  }
    const String arg2 = nlua_pop_String(lstate, &err);
  if (ERROR_SET(&err)) {
    goto exit_0;
  }

    const Buffer arg1 = nlua_pop_Buffer(lstate, &err);
  if (ERROR_SET(&err)) {
    goto exit_1;
  }

  nvim_buf_del_var(arg1, arg2, &err);

  api_free_buffer(arg1);
exit_1:
  api_free_string(arg2);

exit_0:
  if (ERROR_SET(&err)) {
    luaL_where(lstate, 1);
    lua_pushstring(lstate, err.msg);
    api_clear_error(&err);
    lua_concat(lstate, 2);
    return lua_error(lstate);
  }

  return 0;
}

static int nlua_api_nvim_buf_get_name(lua_State *lstate)
{
  Error err = ERROR_INIT;
  if (lua_gettop(lstate) != 1) {
    api_set_error(&err, kErrorTypeValidation, "Expected 1 argument");
    goto exit_0;
  }
  if (!nlua_is_deferred_safe()) {
    return luaL_error(lstate, e_luv_api_disabled, "nvim_buf_get_name");
  }
    const Buffer arg1 = nlua_pop_Buffer(lstate, &err);
  if (ERROR_SET(&err)) {
    goto exit_0;
  }

  Arena arena = ARENA_EMPTY;
  const String ret = nvim_buf_get_name(arg1, &arena, &err);
  nlua_push_String(lstate, ret, true);
arena_mem_free(arena_finish(&arena));

  api_free_buffer(arg1);

exit_0:
  if (ERROR_SET(&err)) {
    luaL_where(lstate, 1);
    lua_pushstring(lstate, err.msg);
    api_clear_error(&err);
    lua_concat(lstate, 2);
    return lua_error(lstate);
  }

  return 1;
}

static int nlua_api_nvim_buf_set_name(lua_State *lstate)
{
  Error err = ERROR_INIT;
  if (lua_gettop(lstate) != 2) {
    api_set_error(&err, kErrorTypeValidation, "Expected 2 arguments");
    goto exit_0;
  }
  if (!nlua_is_deferred_safe()) {
    return luaL_error(lstate, e_luv_api_disabled, "nvim_buf_set_name");
  }
    const String arg2 = nlua_pop_String(lstate, &err);
  if (ERROR_SET(&err)) {
    goto exit_0;
  }

    const Buffer arg1 = nlua_pop_Buffer(lstate, &err);
  if (ERROR_SET(&err)) {
    goto exit_1;
  }

  nvim_buf_set_name(arg1, arg2, &err);

  api_free_buffer(arg1);
exit_1:
  api_free_string(arg2);

exit_0:
  if (ERROR_SET(&err)) {
    luaL_where(lstate, 1);
    lua_pushstring(lstate, err.msg);
    api_clear_error(&err);
    lua_concat(lstate, 2);
    return lua_error(lstate);
  }

  return 0;
}

static int nlua_api_nvim_buf_is_loaded(lua_State *lstate)
{
  Error err = ERROR_INIT;
  if (lua_gettop(lstate) != 1) {
    api_set_error(&err, kErrorTypeValidation, "Expected 1 argument");
    goto exit_0;
  }
  if (!nlua_is_deferred_safe()) {
    return luaL_error(lstate, e_luv_api_disabled, "nvim_buf_is_loaded");
  }
    const Buffer arg1 = nlua_pop_Buffer(lstate, &err);
  if (ERROR_SET(&err)) {
    goto exit_0;
  }

  const Boolean ret = nvim_buf_is_loaded(arg1);
  nlua_push_Boolean(lstate, ret, true);
api_free_boolean(ret);

  api_free_buffer(arg1);

exit_0:
  if (ERROR_SET(&err)) {
    luaL_where(lstate, 1);
    lua_pushstring(lstate, err.msg);
    api_clear_error(&err);
    lua_concat(lstate, 2);
    return lua_error(lstate);
  }

  return 1;
}

static int nlua_api_nvim_buf_delete(lua_State *lstate)
{
  Error err = ERROR_INIT;
  if (lua_gettop(lstate) != 2) {
    api_set_error(&err, kErrorTypeValidation, "Expected 2 arguments");
    goto exit_0;
  }
  if (!nlua_is_deferred_safe()) {
    return luaL_error(lstate, e_luv_api_disabled, "nvim_buf_delete");
  }
  if (textlock != 0) {
    api_set_error(&err, kErrorTypeException, "%s", e_textlock);
    goto exit_0;
  }
    const Dictionary arg2 = nlua_pop_Dictionary(lstate, false, &err);
  if (ERROR_SET(&err)) {
    goto exit_0;
  }

    const Buffer arg1 = nlua_pop_Buffer(lstate, &err);
  if (ERROR_SET(&err)) {
    goto exit_1;
  }

  nvim_buf_delete(arg1, arg2, &err);

  api_free_buffer(arg1);
exit_1:
  api_free_dictionary(arg2);

exit_0:
  if (ERROR_SET(&err)) {
    luaL_where(lstate, 1);
    lua_pushstring(lstate, err.msg);
    api_clear_error(&err);
    lua_concat(lstate, 2);
    return lua_error(lstate);
  }

  return 0;
}

static int nlua_api_nvim_buf_is_valid(lua_State *lstate)
{
  Error err = ERROR_INIT;
  if (lua_gettop(lstate) != 1) {
    api_set_error(&err, kErrorTypeValidation, "Expected 1 argument");
    goto exit_0;
  }
  if (!nlua_is_deferred_safe()) {
    return luaL_error(lstate, e_luv_api_disabled, "nvim_buf_is_valid");
  }
    const Buffer arg1 = nlua_pop_Buffer(lstate, &err);
  if (ERROR_SET(&err)) {
    goto exit_0;
  }

  const Boolean ret = nvim_buf_is_valid(arg1);
  nlua_push_Boolean(lstate, ret, true);
api_free_boolean(ret);

  api_free_buffer(arg1);

exit_0:
  if (ERROR_SET(&err)) {
    luaL_where(lstate, 1);
    lua_pushstring(lstate, err.msg);
    api_clear_error(&err);
    lua_concat(lstate, 2);
    return lua_error(lstate);
  }

  return 1;
}

static int nlua_api_nvim_buf_del_mark(lua_State *lstate)
{
  Error err = ERROR_INIT;
  if (lua_gettop(lstate) != 2) {
    api_set_error(&err, kErrorTypeValidation, "Expected 2 arguments");
    goto exit_0;
  }
  if (!nlua_is_deferred_safe()) {
    return luaL_error(lstate, e_luv_api_disabled, "nvim_buf_del_mark");
  }
    const String arg2 = nlua_pop_String(lstate, &err);
  if (ERROR_SET(&err)) {
    goto exit_0;
  }

    const Buffer arg1 = nlua_pop_Buffer(lstate, &err);
  if (ERROR_SET(&err)) {
    goto exit_1;
  }

  const Boolean ret = nvim_buf_del_mark(arg1, arg2, &err);
  nlua_push_Boolean(lstate, ret, true);
api_free_boolean(ret);

  api_free_buffer(arg1);
exit_1:
  api_free_string(arg2);

exit_0:
  if (ERROR_SET(&err)) {
    luaL_where(lstate, 1);
    lua_pushstring(lstate, err.msg);
    api_clear_error(&err);
    lua_concat(lstate, 2);
    return lua_error(lstate);
  }

  return 1;
}

static int nlua_api_nvim_buf_set_mark(lua_State *lstate)
{
  Error err = ERROR_INIT;
  if (lua_gettop(lstate) != 5) {
    api_set_error(&err, kErrorTypeValidation, "Expected 5 arguments");
    goto exit_0;
  }
  if (!nlua_is_deferred_safe()) {
    return luaL_error(lstate, e_luv_api_disabled, "nvim_buf_set_mark");
  }
    const Dictionary arg5 = nlua_pop_Dictionary(lstate, false, &err);
  if (ERROR_SET(&err)) {
    goto exit_0;
  }

    const Integer arg4 = nlua_pop_Integer(lstate, &err);
  if (ERROR_SET(&err)) {
    goto exit_1;
  }

    const Integer arg3 = nlua_pop_Integer(lstate, &err);
  if (ERROR_SET(&err)) {
    goto exit_2;
  }

    const String arg2 = nlua_pop_String(lstate, &err);
  if (ERROR_SET(&err)) {
    goto exit_3;
  }

    const Buffer arg1 = nlua_pop_Buffer(lstate, &err);
  if (ERROR_SET(&err)) {
    goto exit_4;
  }

  const Boolean ret = nvim_buf_set_mark(arg1, arg2, arg3, arg4, arg5, &err);
  nlua_push_Boolean(lstate, ret, true);
api_free_boolean(ret);

  api_free_buffer(arg1);
exit_4:
  api_free_string(arg2);
exit_3:
  api_free_integer(arg3);
exit_2:
  api_free_integer(arg4);
exit_1:
  api_free_dictionary(arg5);

exit_0:
  if (ERROR_SET(&err)) {
    luaL_where(lstate, 1);
    lua_pushstring(lstate, err.msg);
    api_clear_error(&err);
    lua_concat(lstate, 2);
    return lua_error(lstate);
  }

  return 1;
}

static int nlua_api_nvim_buf_get_mark(lua_State *lstate)
{
  Error err = ERROR_INIT;
  if (lua_gettop(lstate) != 2) {
    api_set_error(&err, kErrorTypeValidation, "Expected 2 arguments");
    goto exit_0;
  }
  if (!nlua_is_deferred_safe()) {
    return luaL_error(lstate, e_luv_api_disabled, "nvim_buf_get_mark");
  }
    const String arg2 = nlua_pop_String(lstate, &err);
  if (ERROR_SET(&err)) {
    goto exit_0;
  }

    const Buffer arg1 = nlua_pop_Buffer(lstate, &err);
  if (ERROR_SET(&err)) {
    goto exit_1;
  }

  const ArrayOf(Integer, 2) ret = nvim_buf_get_mark(arg1, arg2, &err);
  nlua_push_Array(lstate, ret, true);
api_free_array(ret);

  api_free_buffer(arg1);
exit_1:
  api_free_string(arg2);

exit_0:
  if (ERROR_SET(&err)) {
    luaL_where(lstate, 1);
    lua_pushstring(lstate, err.msg);
    api_clear_error(&err);
    lua_concat(lstate, 2);
    return lua_error(lstate);
  }

  return 1;
}

static int nlua_api_nvim_buf_call(lua_State *lstate)
{
  Error err = ERROR_INIT;
  if (lua_gettop(lstate) != 2) {
    api_set_error(&err, kErrorTypeValidation, "Expected 2 arguments");
    goto exit_0;
  }
  if (!nlua_is_deferred_safe()) {
    return luaL_error(lstate, e_luv_api_disabled, "nvim_buf_call");
  }
    const LuaRef arg2 = nlua_pop_LuaRef(lstate, &err);
  if (ERROR_SET(&err)) {
    goto exit_0;
  }

    const Buffer arg1 = nlua_pop_Buffer(lstate, &err);
  if (ERROR_SET(&err)) {
    goto exit_1;
  }

  const Object ret = nvim_buf_call(arg1, arg2, &err);
  nlua_push_Object(lstate, ret, true);
api_free_object(ret);

  api_free_buffer(arg1);
exit_1:
  api_free_luaref(arg2);

exit_0:
  if (ERROR_SET(&err)) {
    luaL_where(lstate, 1);
    lua_pushstring(lstate, err.msg);
    api_clear_error(&err);
    lua_concat(lstate, 2);
    return lua_error(lstate);
  }

  return 1;
}

static int nlua_api_nvim__buf_stats(lua_State *lstate)
{
  Error err = ERROR_INIT;
  if (lua_gettop(lstate) != 1) {
    api_set_error(&err, kErrorTypeValidation, "Expected 1 argument");
    goto exit_0;
  }
  if (!nlua_is_deferred_safe()) {
    return luaL_error(lstate, e_luv_api_disabled, "nvim__buf_stats");
  }
    const Buffer arg1 = nlua_pop_Buffer(lstate, &err);
  if (ERROR_SET(&err)) {
    goto exit_0;
  }

  const Dictionary ret = nvim__buf_stats(arg1, &err);
  nlua_push_Dictionary(lstate, ret, true);
api_free_dictionary(ret);

  api_free_buffer(arg1);

exit_0:
  if (ERROR_SET(&err)) {
    luaL_where(lstate, 1);
    lua_pushstring(lstate, err.msg);
    api_clear_error(&err);
    lua_concat(lstate, 2);
    return lua_error(lstate);
  }

  return 1;
}

static int nlua_api_nvim_parse_cmd(lua_State *lstate)
{
  Error err = ERROR_INIT;
  if (lua_gettop(lstate) != 2) {
    api_set_error(&err, kErrorTypeValidation, "Expected 2 arguments");
    goto exit_0;
  }
    const Dictionary arg2 = nlua_pop_Dictionary(lstate, false, &err);
  if (ERROR_SET(&err)) {
    goto exit_0;
  }

    const String arg1 = nlua_pop_String(lstate, &err);
  if (ERROR_SET(&err)) {
    goto exit_1;
  }

  const Dictionary ret = nvim_parse_cmd(arg1, arg2, &err);
  nlua_push_Dictionary(lstate, ret, true);
api_free_dictionary(ret);

  api_free_string(arg1);
exit_1:
  api_free_dictionary(arg2);

exit_0:
  if (ERROR_SET(&err)) {
    luaL_where(lstate, 1);
    lua_pushstring(lstate, err.msg);
    api_clear_error(&err);
    lua_concat(lstate, 2);
    return lua_error(lstate);
  }

  return 1;
}

static int nlua_api_nvim_cmd(lua_State *lstate)
{
  Error err = ERROR_INIT;
  if (lua_gettop(lstate) != 2) {
    api_set_error(&err, kErrorTypeValidation, "Expected 2 arguments");
    goto exit_0;
  }
  if (!nlua_is_deferred_safe()) {
    return luaL_error(lstate, e_luv_api_disabled, "nvim_cmd");
  }
    KeyDict_cmd_opts arg2 = { 0 }; nlua_pop_keydict(lstate, &arg2, KeyDict_cmd_opts_get_field, &err);
  if (ERROR_SET(&err)) {
    goto exit_1;
  }

    KeyDict_cmd arg1 = { 0 }; nlua_pop_keydict(lstate, &arg1, KeyDict_cmd_get_field, &err);
  if (ERROR_SET(&err)) {
    goto exit_2;
  }

  const String ret = nvim_cmd(LUA_INTERNAL_CALL, &arg1, &arg2, &err);
  nlua_push_String(lstate, ret, true);
api_free_string(ret);

exit_2:
  api_free_keydict_cmd(&arg1);
exit_1:
  api_free_keydict_cmd_opts(&arg2);

exit_0:
  if (ERROR_SET(&err)) {
    luaL_where(lstate, 1);
    lua_pushstring(lstate, err.msg);
    api_clear_error(&err);
    lua_concat(lstate, 2);
    return lua_error(lstate);
  }

  return 1;
}

static int nlua_api_nvim_create_user_command(lua_State *lstate)
{
  Error err = ERROR_INIT;
  if (lua_gettop(lstate) != 3) {
    api_set_error(&err, kErrorTypeValidation, "Expected 3 arguments");
    goto exit_0;
  }
  if (!nlua_is_deferred_safe()) {
    return luaL_error(lstate, e_luv_api_disabled, "nvim_create_user_command");
  }
    KeyDict_user_command arg3 = { 0 }; nlua_pop_keydict(lstate, &arg3, KeyDict_user_command_get_field, &err);
  if (ERROR_SET(&err)) {
    goto exit_1;
  }

    const Object arg2 = nlua_pop_Object(lstate, true, &err);
  if (ERROR_SET(&err)) {
    goto exit_1;
  }

    const String arg1 = nlua_pop_String(lstate, &err);
  if (ERROR_SET(&err)) {
    goto exit_2;
  }

  nvim_create_user_command(arg1, arg2, &arg3, &err);

  api_free_string(arg1);
exit_2:
  api_free_object(arg2);
exit_1:
  api_free_keydict_user_command(&arg3);

exit_0:
  if (ERROR_SET(&err)) {
    luaL_where(lstate, 1);
    lua_pushstring(lstate, err.msg);
    api_clear_error(&err);
    lua_concat(lstate, 2);
    return lua_error(lstate);
  }

  return 0;
}

static int nlua_api_nvim_del_user_command(lua_State *lstate)
{
  Error err = ERROR_INIT;
  if (lua_gettop(lstate) != 1) {
    api_set_error(&err, kErrorTypeValidation, "Expected 1 argument");
    goto exit_0;
  }
  if (!nlua_is_deferred_safe()) {
    return luaL_error(lstate, e_luv_api_disabled, "nvim_del_user_command");
  }
    const String arg1 = nlua_pop_String(lstate, &err);
  if (ERROR_SET(&err)) {
    goto exit_0;
  }

  nvim_del_user_command(arg1, &err);

  api_free_string(arg1);

exit_0:
  if (ERROR_SET(&err)) {
    luaL_where(lstate, 1);
    lua_pushstring(lstate, err.msg);
    api_clear_error(&err);
    lua_concat(lstate, 2);
    return lua_error(lstate);
  }

  return 0;
}

static int nlua_api_nvim_buf_create_user_command(lua_State *lstate)
{
  Error err = ERROR_INIT;
  if (lua_gettop(lstate) != 4) {
    api_set_error(&err, kErrorTypeValidation, "Expected 4 arguments");
    goto exit_0;
  }
  if (!nlua_is_deferred_safe()) {
    return luaL_error(lstate, e_luv_api_disabled, "nvim_buf_create_user_command");
  }
    KeyDict_user_command arg4 = { 0 }; nlua_pop_keydict(lstate, &arg4, KeyDict_user_command_get_field, &err);
  if (ERROR_SET(&err)) {
    goto exit_1;
  }

    const Object arg3 = nlua_pop_Object(lstate, true, &err);
  if (ERROR_SET(&err)) {
    goto exit_1;
  }

    const String arg2 = nlua_pop_String(lstate, &err);
  if (ERROR_SET(&err)) {
    goto exit_2;
  }

    const Buffer arg1 = nlua_pop_Buffer(lstate, &err);
  if (ERROR_SET(&err)) {
    goto exit_3;
  }

  nvim_buf_create_user_command(arg1, arg2, arg3, &arg4, &err);

  api_free_buffer(arg1);
exit_3:
  api_free_string(arg2);
exit_2:
  api_free_object(arg3);
exit_1:
  api_free_keydict_user_command(&arg4);

exit_0:
  if (ERROR_SET(&err)) {
    luaL_where(lstate, 1);
    lua_pushstring(lstate, err.msg);
    api_clear_error(&err);
    lua_concat(lstate, 2);
    return lua_error(lstate);
  }

  return 0;
}

static int nlua_api_nvim_buf_del_user_command(lua_State *lstate)
{
  Error err = ERROR_INIT;
  if (lua_gettop(lstate) != 2) {
    api_set_error(&err, kErrorTypeValidation, "Expected 2 arguments");
    goto exit_0;
  }
  if (!nlua_is_deferred_safe()) {
    return luaL_error(lstate, e_luv_api_disabled, "nvim_buf_del_user_command");
  }
    const String arg2 = nlua_pop_String(lstate, &err);
  if (ERROR_SET(&err)) {
    goto exit_0;
  }

    const Buffer arg1 = nlua_pop_Buffer(lstate, &err);
  if (ERROR_SET(&err)) {
    goto exit_1;
  }

  nvim_buf_del_user_command(arg1, arg2, &err);

  api_free_buffer(arg1);
exit_1:
  api_free_string(arg2);

exit_0:
  if (ERROR_SET(&err)) {
    luaL_where(lstate, 1);
    lua_pushstring(lstate, err.msg);
    api_clear_error(&err);
    lua_concat(lstate, 2);
    return lua_error(lstate);
  }

  return 0;
}

static int nlua_api_nvim_get_commands(lua_State *lstate)
{
  Error err = ERROR_INIT;
  if (lua_gettop(lstate) != 1) {
    api_set_error(&err, kErrorTypeValidation, "Expected 1 argument");
    goto exit_0;
  }
  if (!nlua_is_deferred_safe()) {
    return luaL_error(lstate, e_luv_api_disabled, "nvim_get_commands");
  }
    KeyDict_get_commands arg1 = { 0 }; nlua_pop_keydict(lstate, &arg1, KeyDict_get_commands_get_field, &err);
  if (ERROR_SET(&err)) {
    goto exit_1;
  }

  const Dictionary ret = nvim_get_commands(&arg1, &err);
  nlua_push_Dictionary(lstate, ret, true);
api_free_dictionary(ret);

exit_1:
  api_free_keydict_get_commands(&arg1);

exit_0:
  if (ERROR_SET(&err)) {
    luaL_where(lstate, 1);
    lua_pushstring(lstate, err.msg);
    api_clear_error(&err);
    lua_concat(lstate, 2);
    return lua_error(lstate);
  }

  return 1;
}

static int nlua_api_nvim_buf_get_commands(lua_State *lstate)
{
  Error err = ERROR_INIT;
  if (lua_gettop(lstate) != 2) {
    api_set_error(&err, kErrorTypeValidation, "Expected 2 arguments");
    goto exit_0;
  }
  if (!nlua_is_deferred_safe()) {
    return luaL_error(lstate, e_luv_api_disabled, "nvim_buf_get_commands");
  }
    KeyDict_get_commands arg2 = { 0 }; nlua_pop_keydict(lstate, &arg2, KeyDict_get_commands_get_field, &err);
  if (ERROR_SET(&err)) {
    goto exit_1;
  }

    const Buffer arg1 = nlua_pop_Buffer(lstate, &err);
  if (ERROR_SET(&err)) {
    goto exit_1;
  }

  const Dictionary ret = nvim_buf_get_commands(arg1, &arg2, &err);
  nlua_push_Dictionary(lstate, ret, true);
api_free_dictionary(ret);

  api_free_buffer(arg1);
exit_1:
  api_free_keydict_get_commands(&arg2);

exit_0:
  if (ERROR_SET(&err)) {
    luaL_where(lstate, 1);
    lua_pushstring(lstate, err.msg);
    api_clear_error(&err);
    lua_concat(lstate, 2);
    return lua_error(lstate);
  }

  return 1;
}

static int nlua_api_nvim_command_output(lua_State *lstate)
{
  Error err = ERROR_INIT;
  if (lua_gettop(lstate) != 1) {
    api_set_error(&err, kErrorTypeValidation, "Expected 1 argument");
    goto exit_0;
  }
  if (!nlua_is_deferred_safe()) {
    return luaL_error(lstate, e_luv_api_disabled, "nvim_command_output");
  }
    const String arg1 = nlua_pop_String(lstate, &err);
  if (ERROR_SET(&err)) {
    goto exit_0;
  }

  const String ret = nvim_command_output(LUA_INTERNAL_CALL, arg1, &err);
  nlua_push_String(lstate, ret, true);
api_free_string(ret);

  api_free_string(arg1);

exit_0:
  if (ERROR_SET(&err)) {
    luaL_where(lstate, 1);
    lua_pushstring(lstate, err.msg);
    api_clear_error(&err);
    lua_concat(lstate, 2);
    return lua_error(lstate);
  }

  return 1;
}

static int nlua_api_nvim_buf_get_number(lua_State *lstate)
{
  Error err = ERROR_INIT;
  if (lua_gettop(lstate) != 1) {
    api_set_error(&err, kErrorTypeValidation, "Expected 1 argument");
    goto exit_0;
  }
  if (!nlua_is_deferred_safe()) {
    return luaL_error(lstate, e_luv_api_disabled, "nvim_buf_get_number");
  }
    const Buffer arg1 = nlua_pop_Buffer(lstate, &err);
  if (ERROR_SET(&err)) {
    goto exit_0;
  }

  const Integer ret = nvim_buf_get_number(arg1, &err);
  nlua_push_Integer(lstate, ret, true);
api_free_integer(ret);

  api_free_buffer(arg1);

exit_0:
  if (ERROR_SET(&err)) {
    luaL_where(lstate, 1);
    lua_pushstring(lstate, err.msg);
    api_clear_error(&err);
    lua_concat(lstate, 2);
    return lua_error(lstate);
  }

  return 1;
}

static int nlua_api_nvim_buf_clear_highlight(lua_State *lstate)
{
  Error err = ERROR_INIT;
  if (lua_gettop(lstate) != 4) {
    api_set_error(&err, kErrorTypeValidation, "Expected 4 arguments");
    goto exit_0;
  }
  if (!nlua_is_deferred_safe()) {
    return luaL_error(lstate, e_luv_api_disabled, "nvim_buf_clear_highlight");
  }
    const Integer arg4 = nlua_pop_Integer(lstate, &err);
  if (ERROR_SET(&err)) {
    goto exit_0;
  }

    const Integer arg3 = nlua_pop_Integer(lstate, &err);
  if (ERROR_SET(&err)) {
    goto exit_1;
  }

    const Integer arg2 = nlua_pop_Integer(lstate, &err);
  if (ERROR_SET(&err)) {
    goto exit_2;
  }

    const Buffer arg1 = nlua_pop_Buffer(lstate, &err);
  if (ERROR_SET(&err)) {
    goto exit_3;
  }

  nvim_buf_clear_highlight(arg1, arg2, arg3, arg4, &err);

  api_free_buffer(arg1);
exit_3:
  api_free_integer(arg2);
exit_2:
  api_free_integer(arg3);
exit_1:
  api_free_integer(arg4);

exit_0:
  if (ERROR_SET(&err)) {
    luaL_where(lstate, 1);
    lua_pushstring(lstate, err.msg);
    api_clear_error(&err);
    lua_concat(lstate, 2);
    return lua_error(lstate);
  }

  return 0;
}

static int nlua_api_nvim_buf_set_virtual_text(lua_State *lstate)
{
  Error err = ERROR_INIT;
  if (lua_gettop(lstate) != 5) {
    api_set_error(&err, kErrorTypeValidation, "Expected 5 arguments");
    goto exit_0;
  }
  if (!nlua_is_deferred_safe()) {
    return luaL_error(lstate, e_luv_api_disabled, "nvim_buf_set_virtual_text");
  }
    const Dictionary arg5 = nlua_pop_Dictionary(lstate, false, &err);
  if (ERROR_SET(&err)) {
    goto exit_0;
  }

    const Array arg4 = nlua_pop_Array(lstate, &err);
  if (ERROR_SET(&err)) {
    goto exit_1;
  }

    const Integer arg3 = nlua_pop_Integer(lstate, &err);
  if (ERROR_SET(&err)) {
    goto exit_2;
  }

    const Integer arg2 = nlua_pop_Integer(lstate, &err);
  if (ERROR_SET(&err)) {
    goto exit_3;
  }

    const Buffer arg1 = nlua_pop_Buffer(lstate, &err);
  if (ERROR_SET(&err)) {
    goto exit_4;
  }

  const Integer ret = nvim_buf_set_virtual_text(arg1, arg2, arg3, arg4, arg5, &err);
  nlua_push_Integer(lstate, ret, true);
api_free_integer(ret);

  api_free_buffer(arg1);
exit_4:
  api_free_integer(arg2);
exit_3:
  api_free_integer(arg3);
exit_2:
  api_free_array(arg4);
exit_1:
  api_free_dictionary(arg5);

exit_0:
  if (ERROR_SET(&err)) {
    luaL_where(lstate, 1);
    lua_pushstring(lstate, err.msg);
    api_clear_error(&err);
    lua_concat(lstate, 2);
    return lua_error(lstate);
  }

  return 1;
}

static int nlua_api_nvim_create_namespace(lua_State *lstate)
{
  Error err = ERROR_INIT;
  if (lua_gettop(lstate) != 1) {
    api_set_error(&err, kErrorTypeValidation, "Expected 1 argument");
    goto exit_0;
  }
  if (!nlua_is_deferred_safe()) {
    return luaL_error(lstate, e_luv_api_disabled, "nvim_create_namespace");
  }
    const String arg1 = nlua_pop_String(lstate, &err);
  if (ERROR_SET(&err)) {
    goto exit_0;
  }

  const Integer ret = nvim_create_namespace(arg1);
  nlua_push_Integer(lstate, ret, true);
api_free_integer(ret);

  api_free_string(arg1);

exit_0:
  if (ERROR_SET(&err)) {
    luaL_where(lstate, 1);
    lua_pushstring(lstate, err.msg);
    api_clear_error(&err);
    lua_concat(lstate, 2);
    return lua_error(lstate);
  }

  return 1;
}

static int nlua_api_nvim_get_namespaces(lua_State *lstate)
{
  Error err = ERROR_INIT;
  if (lua_gettop(lstate) != 0) {
    api_set_error(&err, kErrorTypeValidation, "Expected 0 arguments");
    goto exit_0;
  }
  if (!nlua_is_deferred_safe()) {
    return luaL_error(lstate, e_luv_api_disabled, "nvim_get_namespaces");
  }
  const Dictionary ret = nvim_get_namespaces();
  nlua_push_Dictionary(lstate, ret, true);
api_free_dictionary(ret);


exit_0:
  if (ERROR_SET(&err)) {
    luaL_where(lstate, 1);
    lua_pushstring(lstate, err.msg);
    api_clear_error(&err);
    lua_concat(lstate, 2);
    return lua_error(lstate);
  }

  return 1;
}

static int nlua_api_nvim_buf_get_extmark_by_id(lua_State *lstate)
{
  Error err = ERROR_INIT;
  if (lua_gettop(lstate) != 4) {
    api_set_error(&err, kErrorTypeValidation, "Expected 4 arguments");
    goto exit_0;
  }
  if (!nlua_is_deferred_safe()) {
    return luaL_error(lstate, e_luv_api_disabled, "nvim_buf_get_extmark_by_id");
  }
    const Dictionary arg4 = nlua_pop_Dictionary(lstate, false, &err);
  if (ERROR_SET(&err)) {
    goto exit_0;
  }

    const Integer arg3 = nlua_pop_Integer(lstate, &err);
  if (ERROR_SET(&err)) {
    goto exit_1;
  }

    const Integer arg2 = nlua_pop_Integer(lstate, &err);
  if (ERROR_SET(&err)) {
    goto exit_2;
  }

    const Buffer arg1 = nlua_pop_Buffer(lstate, &err);
  if (ERROR_SET(&err)) {
    goto exit_3;
  }

  const ArrayOf(Integer) ret = nvim_buf_get_extmark_by_id(arg1, arg2, arg3, arg4, &err);
  nlua_push_Array(lstate, ret, true);
api_free_array(ret);

  api_free_buffer(arg1);
exit_3:
  api_free_integer(arg2);
exit_2:
  api_free_integer(arg3);
exit_1:
  api_free_dictionary(arg4);

exit_0:
  if (ERROR_SET(&err)) {
    luaL_where(lstate, 1);
    lua_pushstring(lstate, err.msg);
    api_clear_error(&err);
    lua_concat(lstate, 2);
    return lua_error(lstate);
  }

  return 1;
}

static int nlua_api_nvim_buf_get_extmarks(lua_State *lstate)
{
  Error err = ERROR_INIT;
  if (lua_gettop(lstate) != 5) {
    api_set_error(&err, kErrorTypeValidation, "Expected 5 arguments");
    goto exit_0;
  }
  if (!nlua_is_deferred_safe()) {
    return luaL_error(lstate, e_luv_api_disabled, "nvim_buf_get_extmarks");
  }
    const Dictionary arg5 = nlua_pop_Dictionary(lstate, false, &err);
  if (ERROR_SET(&err)) {
    goto exit_0;
  }

    const Object arg4 = nlua_pop_Object(lstate, true, &err);
  if (ERROR_SET(&err)) {
    goto exit_1;
  }

    const Object arg3 = nlua_pop_Object(lstate, true, &err);
  if (ERROR_SET(&err)) {
    goto exit_2;
  }

    const Integer arg2 = nlua_pop_Integer(lstate, &err);
  if (ERROR_SET(&err)) {
    goto exit_3;
  }

    const Buffer arg1 = nlua_pop_Buffer(lstate, &err);
  if (ERROR_SET(&err)) {
    goto exit_4;
  }

  const Array ret = nvim_buf_get_extmarks(arg1, arg2, arg3, arg4, arg5, &err);
  nlua_push_Array(lstate, ret, true);
api_free_array(ret);

  api_free_buffer(arg1);
exit_4:
  api_free_integer(arg2);
exit_3:
  api_free_object(arg3);
exit_2:
  api_free_object(arg4);
exit_1:
  api_free_dictionary(arg5);

exit_0:
  if (ERROR_SET(&err)) {
    luaL_where(lstate, 1);
    lua_pushstring(lstate, err.msg);
    api_clear_error(&err);
    lua_concat(lstate, 2);
    return lua_error(lstate);
  }

  return 1;
}

static int nlua_api_nvim_buf_set_extmark(lua_State *lstate)
{
  Error err = ERROR_INIT;
  if (lua_gettop(lstate) != 5) {
    api_set_error(&err, kErrorTypeValidation, "Expected 5 arguments");
    goto exit_0;
  }
  if (!nlua_is_deferred_safe()) {
    return luaL_error(lstate, e_luv_api_disabled, "nvim_buf_set_extmark");
  }
    KeyDict_set_extmark arg5 = { 0 }; nlua_pop_keydict(lstate, &arg5, KeyDict_set_extmark_get_field, &err);
  if (ERROR_SET(&err)) {
    goto exit_1;
  }

    const Integer arg4 = nlua_pop_Integer(lstate, &err);
  if (ERROR_SET(&err)) {
    goto exit_1;
  }

    const Integer arg3 = nlua_pop_Integer(lstate, &err);
  if (ERROR_SET(&err)) {
    goto exit_2;
  }

    const Integer arg2 = nlua_pop_Integer(lstate, &err);
  if (ERROR_SET(&err)) {
    goto exit_3;
  }

    const Buffer arg1 = nlua_pop_Buffer(lstate, &err);
  if (ERROR_SET(&err)) {
    goto exit_4;
  }

  const Integer ret = nvim_buf_set_extmark(arg1, arg2, arg3, arg4, &arg5, &err);
  nlua_push_Integer(lstate, ret, true);
api_free_integer(ret);

  api_free_buffer(arg1);
exit_4:
  api_free_integer(arg2);
exit_3:
  api_free_integer(arg3);
exit_2:
  api_free_integer(arg4);
exit_1:
  api_free_keydict_set_extmark(&arg5);

exit_0:
  if (ERROR_SET(&err)) {
    luaL_where(lstate, 1);
    lua_pushstring(lstate, err.msg);
    api_clear_error(&err);
    lua_concat(lstate, 2);
    return lua_error(lstate);
  }

  return 1;
}

static int nlua_api_nvim_buf_del_extmark(lua_State *lstate)
{
  Error err = ERROR_INIT;
  if (lua_gettop(lstate) != 3) {
    api_set_error(&err, kErrorTypeValidation, "Expected 3 arguments");
    goto exit_0;
  }
  if (!nlua_is_deferred_safe()) {
    return luaL_error(lstate, e_luv_api_disabled, "nvim_buf_del_extmark");
  }
    const Integer arg3 = nlua_pop_Integer(lstate, &err);
  if (ERROR_SET(&err)) {
    goto exit_0;
  }

    const Integer arg2 = nlua_pop_Integer(lstate, &err);
  if (ERROR_SET(&err)) {
    goto exit_1;
  }

    const Buffer arg1 = nlua_pop_Buffer(lstate, &err);
  if (ERROR_SET(&err)) {
    goto exit_2;
  }

  const Boolean ret = nvim_buf_del_extmark(arg1, arg2, arg3, &err);
  nlua_push_Boolean(lstate, ret, true);
api_free_boolean(ret);

  api_free_buffer(arg1);
exit_2:
  api_free_integer(arg2);
exit_1:
  api_free_integer(arg3);

exit_0:
  if (ERROR_SET(&err)) {
    luaL_where(lstate, 1);
    lua_pushstring(lstate, err.msg);
    api_clear_error(&err);
    lua_concat(lstate, 2);
    return lua_error(lstate);
  }

  return 1;
}

static int nlua_api_nvim_buf_add_highlight(lua_State *lstate)
{
  Error err = ERROR_INIT;
  if (lua_gettop(lstate) != 6) {
    api_set_error(&err, kErrorTypeValidation, "Expected 6 arguments");
    goto exit_0;
  }
  if (!nlua_is_deferred_safe()) {
    return luaL_error(lstate, e_luv_api_disabled, "nvim_buf_add_highlight");
  }
    const Integer arg6 = nlua_pop_Integer(lstate, &err);
  if (ERROR_SET(&err)) {
    goto exit_0;
  }

    const Integer arg5 = nlua_pop_Integer(lstate, &err);
  if (ERROR_SET(&err)) {
    goto exit_1;
  }

    const Integer arg4 = nlua_pop_Integer(lstate, &err);
  if (ERROR_SET(&err)) {
    goto exit_2;
  }

    const String arg3 = nlua_pop_String(lstate, &err);
  if (ERROR_SET(&err)) {
    goto exit_3;
  }

    const Integer arg2 = nlua_pop_Integer(lstate, &err);
  if (ERROR_SET(&err)) {
    goto exit_4;
  }

    const Buffer arg1 = nlua_pop_Buffer(lstate, &err);
  if (ERROR_SET(&err)) {
    goto exit_5;
  }

  const Integer ret = nvim_buf_add_highlight(arg1, arg2, arg3, arg4, arg5, arg6, &err);
  nlua_push_Integer(lstate, ret, true);
api_free_integer(ret);

  api_free_buffer(arg1);
exit_5:
  api_free_integer(arg2);
exit_4:
  api_free_string(arg3);
exit_3:
  api_free_integer(arg4);
exit_2:
  api_free_integer(arg5);
exit_1:
  api_free_integer(arg6);

exit_0:
  if (ERROR_SET(&err)) {
    luaL_where(lstate, 1);
    lua_pushstring(lstate, err.msg);
    api_clear_error(&err);
    lua_concat(lstate, 2);
    return lua_error(lstate);
  }

  return 1;
}

static int nlua_api_nvim_buf_clear_namespace(lua_State *lstate)
{
  Error err = ERROR_INIT;
  if (lua_gettop(lstate) != 4) {
    api_set_error(&err, kErrorTypeValidation, "Expected 4 arguments");
    goto exit_0;
  }
  if (!nlua_is_deferred_safe()) {
    return luaL_error(lstate, e_luv_api_disabled, "nvim_buf_clear_namespace");
  }
    const Integer arg4 = nlua_pop_Integer(lstate, &err);
  if (ERROR_SET(&err)) {
    goto exit_0;
  }

    const Integer arg3 = nlua_pop_Integer(lstate, &err);
  if (ERROR_SET(&err)) {
    goto exit_1;
  }

    const Integer arg2 = nlua_pop_Integer(lstate, &err);
  if (ERROR_SET(&err)) {
    goto exit_2;
  }

    const Buffer arg1 = nlua_pop_Buffer(lstate, &err);
  if (ERROR_SET(&err)) {
    goto exit_3;
  }

  nvim_buf_clear_namespace(arg1, arg2, arg3, arg4, &err);

  api_free_buffer(arg1);
exit_3:
  api_free_integer(arg2);
exit_2:
  api_free_integer(arg3);
exit_1:
  api_free_integer(arg4);

exit_0:
  if (ERROR_SET(&err)) {
    luaL_where(lstate, 1);
    lua_pushstring(lstate, err.msg);
    api_clear_error(&err);
    lua_concat(lstate, 2);
    return lua_error(lstate);
  }

  return 0;
}

static int nlua_api_nvim_set_decoration_provider(lua_State *lstate)
{
  Error err = ERROR_INIT;
  if (lua_gettop(lstate) != 2) {
    api_set_error(&err, kErrorTypeValidation, "Expected 2 arguments");
    goto exit_0;
  }
  if (!nlua_is_deferred_safe()) {
    return luaL_error(lstate, e_luv_api_disabled, "nvim_set_decoration_provider");
  }
    KeyDict_set_decoration_provider arg2 = { 0 }; nlua_pop_keydict(lstate, &arg2, KeyDict_set_decoration_provider_get_field, &err);
  if (ERROR_SET(&err)) {
    goto exit_1;
  }

    const Integer arg1 = nlua_pop_Integer(lstate, &err);
  if (ERROR_SET(&err)) {
    goto exit_1;
  }

  nvim_set_decoration_provider(arg1, &arg2, &err);

  api_free_integer(arg1);
exit_1:
  api_free_keydict_set_decoration_provider(&arg2);

exit_0:
  if (ERROR_SET(&err)) {
    luaL_where(lstate, 1);
    lua_pushstring(lstate, err.msg);
    api_clear_error(&err);
    lua_concat(lstate, 2);
    return lua_error(lstate);
  }

  return 0;
}

static int nlua_api_nvim_get_option_value(lua_State *lstate)
{
  Error err = ERROR_INIT;
  if (lua_gettop(lstate) != 2) {
    api_set_error(&err, kErrorTypeValidation, "Expected 2 arguments");
    goto exit_0;
  }
  if (!nlua_is_deferred_safe()) {
    return luaL_error(lstate, e_luv_api_disabled, "nvim_get_option_value");
  }
    KeyDict_option arg2 = { 0 }; nlua_pop_keydict(lstate, &arg2, KeyDict_option_get_field, &err);
  if (ERROR_SET(&err)) {
    goto exit_1;
  }

    const String arg1 = nlua_pop_String(lstate, &err);
  if (ERROR_SET(&err)) {
    goto exit_1;
  }

  const Object ret = nvim_get_option_value(arg1, &arg2, &err);
  nlua_push_Object(lstate, ret, true);
api_free_object(ret);

  api_free_string(arg1);
exit_1:
  api_free_keydict_option(&arg2);

exit_0:
  if (ERROR_SET(&err)) {
    luaL_where(lstate, 1);
    lua_pushstring(lstate, err.msg);
    api_clear_error(&err);
    lua_concat(lstate, 2);
    return lua_error(lstate);
  }

  return 1;
}

static int nlua_api_nvim_set_option_value(lua_State *lstate)
{
  Error err = ERROR_INIT;
  if (lua_gettop(lstate) != 3) {
    api_set_error(&err, kErrorTypeValidation, "Expected 3 arguments");
    goto exit_0;
  }
  if (!nlua_is_deferred_safe()) {
    return luaL_error(lstate, e_luv_api_disabled, "nvim_set_option_value");
  }
    KeyDict_option arg3 = { 0 }; nlua_pop_keydict(lstate, &arg3, KeyDict_option_get_field, &err);
  if (ERROR_SET(&err)) {
    goto exit_1;
  }

    const Object arg2 = nlua_pop_Object(lstate, true, &err);
  if (ERROR_SET(&err)) {
    goto exit_1;
  }

    const String arg1 = nlua_pop_String(lstate, &err);
  if (ERROR_SET(&err)) {
    goto exit_2;
  }

  nvim_set_option_value(arg1, arg2, &arg3, &err);

  api_free_string(arg1);
exit_2:
  api_free_object(arg2);
exit_1:
  api_free_keydict_option(&arg3);

exit_0:
  if (ERROR_SET(&err)) {
    luaL_where(lstate, 1);
    lua_pushstring(lstate, err.msg);
    api_clear_error(&err);
    lua_concat(lstate, 2);
    return lua_error(lstate);
  }

  return 0;
}

static int nlua_api_nvim_get_all_options_info(lua_State *lstate)
{
  Error err = ERROR_INIT;
  if (lua_gettop(lstate) != 0) {
    api_set_error(&err, kErrorTypeValidation, "Expected 0 arguments");
    goto exit_0;
  }
  if (!nlua_is_deferred_safe()) {
    return luaL_error(lstate, e_luv_api_disabled, "nvim_get_all_options_info");
  }
  const Dictionary ret = nvim_get_all_options_info(&err);
  nlua_push_Dictionary(lstate, ret, true);
api_free_dictionary(ret);


exit_0:
  if (ERROR_SET(&err)) {
    luaL_where(lstate, 1);
    lua_pushstring(lstate, err.msg);
    api_clear_error(&err);
    lua_concat(lstate, 2);
    return lua_error(lstate);
  }

  return 1;
}

static int nlua_api_nvim_get_option_info(lua_State *lstate)
{
  Error err = ERROR_INIT;
  if (lua_gettop(lstate) != 1) {
    api_set_error(&err, kErrorTypeValidation, "Expected 1 argument");
    goto exit_0;
  }
  if (!nlua_is_deferred_safe()) {
    return luaL_error(lstate, e_luv_api_disabled, "nvim_get_option_info");
  }
    const String arg1 = nlua_pop_String(lstate, &err);
  if (ERROR_SET(&err)) {
    goto exit_0;
  }

  const Dictionary ret = nvim_get_option_info(arg1, &err);
  nlua_push_Dictionary(lstate, ret, true);
api_free_dictionary(ret);

  api_free_string(arg1);

exit_0:
  if (ERROR_SET(&err)) {
    luaL_where(lstate, 1);
    lua_pushstring(lstate, err.msg);
    api_clear_error(&err);
    lua_concat(lstate, 2);
    return lua_error(lstate);
  }

  return 1;
}

static int nlua_api_nvim_set_option(lua_State *lstate)
{
  Error err = ERROR_INIT;
  if (lua_gettop(lstate) != 2) {
    api_set_error(&err, kErrorTypeValidation, "Expected 2 arguments");
    goto exit_0;
  }
  if (!nlua_is_deferred_safe()) {
    return luaL_error(lstate, e_luv_api_disabled, "nvim_set_option");
  }
    const Object arg2 = nlua_pop_Object(lstate, true, &err);
  if (ERROR_SET(&err)) {
    goto exit_0;
  }

    const String arg1 = nlua_pop_String(lstate, &err);
  if (ERROR_SET(&err)) {
    goto exit_1;
  }

  nvim_set_option(LUA_INTERNAL_CALL, arg1, arg2, &err);

  api_free_string(arg1);
exit_1:
  api_free_object(arg2);

exit_0:
  if (ERROR_SET(&err)) {
    luaL_where(lstate, 1);
    lua_pushstring(lstate, err.msg);
    api_clear_error(&err);
    lua_concat(lstate, 2);
    return lua_error(lstate);
  }

  return 0;
}

static int nlua_api_nvim_get_option(lua_State *lstate)
{
  Error err = ERROR_INIT;
  if (lua_gettop(lstate) != 1) {
    api_set_error(&err, kErrorTypeValidation, "Expected 1 argument");
    goto exit_0;
  }
  if (!nlua_is_deferred_safe()) {
    return luaL_error(lstate, e_luv_api_disabled, "nvim_get_option");
  }
    const String arg1 = nlua_pop_String(lstate, &err);
  if (ERROR_SET(&err)) {
    goto exit_0;
  }

  const Object ret = nvim_get_option(arg1, &err);
  nlua_push_Object(lstate, ret, true);
api_free_object(ret);

  api_free_string(arg1);

exit_0:
  if (ERROR_SET(&err)) {
    luaL_where(lstate, 1);
    lua_pushstring(lstate, err.msg);
    api_clear_error(&err);
    lua_concat(lstate, 2);
    return lua_error(lstate);
  }

  return 1;
}

static int nlua_api_nvim_buf_get_option(lua_State *lstate)
{
  Error err = ERROR_INIT;
  if (lua_gettop(lstate) != 2) {
    api_set_error(&err, kErrorTypeValidation, "Expected 2 arguments");
    goto exit_0;
  }
  if (!nlua_is_deferred_safe()) {
    return luaL_error(lstate, e_luv_api_disabled, "nvim_buf_get_option");
  }
    const String arg2 = nlua_pop_String(lstate, &err);
  if (ERROR_SET(&err)) {
    goto exit_0;
  }

    const Buffer arg1 = nlua_pop_Buffer(lstate, &err);
  if (ERROR_SET(&err)) {
    goto exit_1;
  }

  const Object ret = nvim_buf_get_option(arg1, arg2, &err);
  nlua_push_Object(lstate, ret, true);
api_free_object(ret);

  api_free_buffer(arg1);
exit_1:
  api_free_string(arg2);

exit_0:
  if (ERROR_SET(&err)) {
    luaL_where(lstate, 1);
    lua_pushstring(lstate, err.msg);
    api_clear_error(&err);
    lua_concat(lstate, 2);
    return lua_error(lstate);
  }

  return 1;
}

static int nlua_api_nvim_buf_set_option(lua_State *lstate)
{
  Error err = ERROR_INIT;
  if (lua_gettop(lstate) != 3) {
    api_set_error(&err, kErrorTypeValidation, "Expected 3 arguments");
    goto exit_0;
  }
  if (!nlua_is_deferred_safe()) {
    return luaL_error(lstate, e_luv_api_disabled, "nvim_buf_set_option");
  }
    const Object arg3 = nlua_pop_Object(lstate, true, &err);
  if (ERROR_SET(&err)) {
    goto exit_0;
  }

    const String arg2 = nlua_pop_String(lstate, &err);
  if (ERROR_SET(&err)) {
    goto exit_1;
  }

    const Buffer arg1 = nlua_pop_Buffer(lstate, &err);
  if (ERROR_SET(&err)) {
    goto exit_2;
  }

  nvim_buf_set_option(LUA_INTERNAL_CALL, arg1, arg2, arg3, &err);

  api_free_buffer(arg1);
exit_2:
  api_free_string(arg2);
exit_1:
  api_free_object(arg3);

exit_0:
  if (ERROR_SET(&err)) {
    luaL_where(lstate, 1);
    lua_pushstring(lstate, err.msg);
    api_clear_error(&err);
    lua_concat(lstate, 2);
    return lua_error(lstate);
  }

  return 0;
}

static int nlua_api_nvim_win_get_option(lua_State *lstate)
{
  Error err = ERROR_INIT;
  if (lua_gettop(lstate) != 2) {
    api_set_error(&err, kErrorTypeValidation, "Expected 2 arguments");
    goto exit_0;
  }
  if (!nlua_is_deferred_safe()) {
    return luaL_error(lstate, e_luv_api_disabled, "nvim_win_get_option");
  }
    const String arg2 = nlua_pop_String(lstate, &err);
  if (ERROR_SET(&err)) {
    goto exit_0;
  }

    const Window arg1 = nlua_pop_Window(lstate, &err);
  if (ERROR_SET(&err)) {
    goto exit_1;
  }

  const Object ret = nvim_win_get_option(arg1, arg2, &err);
  nlua_push_Object(lstate, ret, true);
api_free_object(ret);

  api_free_window(arg1);
exit_1:
  api_free_string(arg2);

exit_0:
  if (ERROR_SET(&err)) {
    luaL_where(lstate, 1);
    lua_pushstring(lstate, err.msg);
    api_clear_error(&err);
    lua_concat(lstate, 2);
    return lua_error(lstate);
  }

  return 1;
}

static int nlua_api_nvim_win_set_option(lua_State *lstate)
{
  Error err = ERROR_INIT;
  if (lua_gettop(lstate) != 3) {
    api_set_error(&err, kErrorTypeValidation, "Expected 3 arguments");
    goto exit_0;
  }
  if (!nlua_is_deferred_safe()) {
    return luaL_error(lstate, e_luv_api_disabled, "nvim_win_set_option");
  }
    const Object arg3 = nlua_pop_Object(lstate, true, &err);
  if (ERROR_SET(&err)) {
    goto exit_0;
  }

    const String arg2 = nlua_pop_String(lstate, &err);
  if (ERROR_SET(&err)) {
    goto exit_1;
  }

    const Window arg1 = nlua_pop_Window(lstate, &err);
  if (ERROR_SET(&err)) {
    goto exit_2;
  }

  nvim_win_set_option(LUA_INTERNAL_CALL, arg1, arg2, arg3, &err);

  api_free_window(arg1);
exit_2:
  api_free_string(arg2);
exit_1:
  api_free_object(arg3);

exit_0:
  if (ERROR_SET(&err)) {
    luaL_where(lstate, 1);
    lua_pushstring(lstate, err.msg);
    api_clear_error(&err);
    lua_concat(lstate, 2);
    return lua_error(lstate);
  }

  return 0;
}

static int nlua_api_nvim_tabpage_list_wins(lua_State *lstate)
{
  Error err = ERROR_INIT;
  if (lua_gettop(lstate) != 1) {
    api_set_error(&err, kErrorTypeValidation, "Expected 1 argument");
    goto exit_0;
  }
  if (!nlua_is_deferred_safe()) {
    return luaL_error(lstate, e_luv_api_disabled, "nvim_tabpage_list_wins");
  }
    const Tabpage arg1 = nlua_pop_Tabpage(lstate, &err);
  if (ERROR_SET(&err)) {
    goto exit_0;
  }

  const ArrayOf(Window) ret = nvim_tabpage_list_wins(arg1, &err);
  nlua_push_Array(lstate, ret, true);
api_free_array(ret);

  api_free_tabpage(arg1);

exit_0:
  if (ERROR_SET(&err)) {
    luaL_where(lstate, 1);
    lua_pushstring(lstate, err.msg);
    api_clear_error(&err);
    lua_concat(lstate, 2);
    return lua_error(lstate);
  }

  return 1;
}

static int nlua_api_nvim_tabpage_get_var(lua_State *lstate)
{
  Error err = ERROR_INIT;
  if (lua_gettop(lstate) != 2) {
    api_set_error(&err, kErrorTypeValidation, "Expected 2 arguments");
    goto exit_0;
  }
  if (!nlua_is_deferred_safe()) {
    return luaL_error(lstate, e_luv_api_disabled, "nvim_tabpage_get_var");
  }
    const String arg2 = nlua_pop_String(lstate, &err);
  if (ERROR_SET(&err)) {
    goto exit_0;
  }

    const Tabpage arg1 = nlua_pop_Tabpage(lstate, &err);
  if (ERROR_SET(&err)) {
    goto exit_1;
  }

  const Object ret = nvim_tabpage_get_var(arg1, arg2, &err);
  nlua_push_Object(lstate, ret, true);
api_free_object(ret);

  api_free_tabpage(arg1);
exit_1:
  api_free_string(arg2);

exit_0:
  if (ERROR_SET(&err)) {
    luaL_where(lstate, 1);
    lua_pushstring(lstate, err.msg);
    api_clear_error(&err);
    lua_concat(lstate, 2);
    return lua_error(lstate);
  }

  return 1;
}

static int nlua_api_nvim_tabpage_set_var(lua_State *lstate)
{
  Error err = ERROR_INIT;
  if (lua_gettop(lstate) != 3) {
    api_set_error(&err, kErrorTypeValidation, "Expected 3 arguments");
    goto exit_0;
  }
  if (!nlua_is_deferred_safe()) {
    return luaL_error(lstate, e_luv_api_disabled, "nvim_tabpage_set_var");
  }
    const Object arg3 = nlua_pop_Object(lstate, true, &err);
  if (ERROR_SET(&err)) {
    goto exit_0;
  }

    const String arg2 = nlua_pop_String(lstate, &err);
  if (ERROR_SET(&err)) {
    goto exit_1;
  }

    const Tabpage arg1 = nlua_pop_Tabpage(lstate, &err);
  if (ERROR_SET(&err)) {
    goto exit_2;
  }

  nvim_tabpage_set_var(arg1, arg2, arg3, &err);

  api_free_tabpage(arg1);
exit_2:
  api_free_string(arg2);
exit_1:
  api_free_object(arg3);

exit_0:
  if (ERROR_SET(&err)) {
    luaL_where(lstate, 1);
    lua_pushstring(lstate, err.msg);
    api_clear_error(&err);
    lua_concat(lstate, 2);
    return lua_error(lstate);
  }

  return 0;
}

static int nlua_api_nvim_tabpage_del_var(lua_State *lstate)
{
  Error err = ERROR_INIT;
  if (lua_gettop(lstate) != 2) {
    api_set_error(&err, kErrorTypeValidation, "Expected 2 arguments");
    goto exit_0;
  }
  if (!nlua_is_deferred_safe()) {
    return luaL_error(lstate, e_luv_api_disabled, "nvim_tabpage_del_var");
  }
    const String arg2 = nlua_pop_String(lstate, &err);
  if (ERROR_SET(&err)) {
    goto exit_0;
  }

    const Tabpage arg1 = nlua_pop_Tabpage(lstate, &err);
  if (ERROR_SET(&err)) {
    goto exit_1;
  }

  nvim_tabpage_del_var(arg1, arg2, &err);

  api_free_tabpage(arg1);
exit_1:
  api_free_string(arg2);

exit_0:
  if (ERROR_SET(&err)) {
    luaL_where(lstate, 1);
    lua_pushstring(lstate, err.msg);
    api_clear_error(&err);
    lua_concat(lstate, 2);
    return lua_error(lstate);
  }

  return 0;
}

static int nlua_api_nvim_tabpage_get_win(lua_State *lstate)
{
  Error err = ERROR_INIT;
  if (lua_gettop(lstate) != 1) {
    api_set_error(&err, kErrorTypeValidation, "Expected 1 argument");
    goto exit_0;
  }
  if (!nlua_is_deferred_safe()) {
    return luaL_error(lstate, e_luv_api_disabled, "nvim_tabpage_get_win");
  }
    const Tabpage arg1 = nlua_pop_Tabpage(lstate, &err);
  if (ERROR_SET(&err)) {
    goto exit_0;
  }

  const Window ret = nvim_tabpage_get_win(arg1, &err);
  nlua_push_Window(lstate, ret, true);
api_free_window(ret);

  api_free_tabpage(arg1);

exit_0:
  if (ERROR_SET(&err)) {
    luaL_where(lstate, 1);
    lua_pushstring(lstate, err.msg);
    api_clear_error(&err);
    lua_concat(lstate, 2);
    return lua_error(lstate);
  }

  return 1;
}

static int nlua_api_nvim_tabpage_get_number(lua_State *lstate)
{
  Error err = ERROR_INIT;
  if (lua_gettop(lstate) != 1) {
    api_set_error(&err, kErrorTypeValidation, "Expected 1 argument");
    goto exit_0;
  }
  if (!nlua_is_deferred_safe()) {
    return luaL_error(lstate, e_luv_api_disabled, "nvim_tabpage_get_number");
  }
    const Tabpage arg1 = nlua_pop_Tabpage(lstate, &err);
  if (ERROR_SET(&err)) {
    goto exit_0;
  }

  const Integer ret = nvim_tabpage_get_number(arg1, &err);
  nlua_push_Integer(lstate, ret, true);
api_free_integer(ret);

  api_free_tabpage(arg1);

exit_0:
  if (ERROR_SET(&err)) {
    luaL_where(lstate, 1);
    lua_pushstring(lstate, err.msg);
    api_clear_error(&err);
    lua_concat(lstate, 2);
    return lua_error(lstate);
  }

  return 1;
}

static int nlua_api_nvim_tabpage_is_valid(lua_State *lstate)
{
  Error err = ERROR_INIT;
  if (lua_gettop(lstate) != 1) {
    api_set_error(&err, kErrorTypeValidation, "Expected 1 argument");
    goto exit_0;
  }
  if (!nlua_is_deferred_safe()) {
    return luaL_error(lstate, e_luv_api_disabled, "nvim_tabpage_is_valid");
  }
    const Tabpage arg1 = nlua_pop_Tabpage(lstate, &err);
  if (ERROR_SET(&err)) {
    goto exit_0;
  }

  const Boolean ret = nvim_tabpage_is_valid(arg1);
  nlua_push_Boolean(lstate, ret, true);
api_free_boolean(ret);

  api_free_tabpage(arg1);

exit_0:
  if (ERROR_SET(&err)) {
    luaL_where(lstate, 1);
    lua_pushstring(lstate, err.msg);
    api_clear_error(&err);
    lua_concat(lstate, 2);
    return lua_error(lstate);
  }

  return 1;
}

static int nlua_api_nvim_get_hl_by_name(lua_State *lstate)
{
  Error err = ERROR_INIT;
  if (lua_gettop(lstate) != 2) {
    api_set_error(&err, kErrorTypeValidation, "Expected 2 arguments");
    goto exit_0;
  }
  if (!nlua_is_deferred_safe()) {
    return luaL_error(lstate, e_luv_api_disabled, "nvim_get_hl_by_name");
  }
    const Boolean arg2 = nlua_pop_Boolean(lstate, &err);
  if (ERROR_SET(&err)) {
    goto exit_0;
  }

    const String arg1 = nlua_pop_String(lstate, &err);
  if (ERROR_SET(&err)) {
    goto exit_1;
  }

  Arena arena = ARENA_EMPTY;
  const Dictionary ret = nvim_get_hl_by_name(arg1, arg2, &arena, &err);
  nlua_push_Dictionary(lstate, ret, true);
arena_mem_free(arena_finish(&arena));

  api_free_string(arg1);
exit_1:
  api_free_boolean(arg2);

exit_0:
  if (ERROR_SET(&err)) {
    luaL_where(lstate, 1);
    lua_pushstring(lstate, err.msg);
    api_clear_error(&err);
    lua_concat(lstate, 2);
    return lua_error(lstate);
  }

  return 1;
}

static int nlua_api_nvim_get_hl_by_id(lua_State *lstate)
{
  Error err = ERROR_INIT;
  if (lua_gettop(lstate) != 2) {
    api_set_error(&err, kErrorTypeValidation, "Expected 2 arguments");
    goto exit_0;
  }
  if (!nlua_is_deferred_safe()) {
    return luaL_error(lstate, e_luv_api_disabled, "nvim_get_hl_by_id");
  }
    const Boolean arg2 = nlua_pop_Boolean(lstate, &err);
  if (ERROR_SET(&err)) {
    goto exit_0;
  }

    const Integer arg1 = nlua_pop_Integer(lstate, &err);
  if (ERROR_SET(&err)) {
    goto exit_1;
  }

  Arena arena = ARENA_EMPTY;
  const Dictionary ret = nvim_get_hl_by_id(arg1, arg2, &arena, &err);
  nlua_push_Dictionary(lstate, ret, true);
arena_mem_free(arena_finish(&arena));

  api_free_integer(arg1);
exit_1:
  api_free_boolean(arg2);

exit_0:
  if (ERROR_SET(&err)) {
    luaL_where(lstate, 1);
    lua_pushstring(lstate, err.msg);
    api_clear_error(&err);
    lua_concat(lstate, 2);
    return lua_error(lstate);
  }

  return 1;
}

static int nlua_api_nvim_get_hl_id_by_name(lua_State *lstate)
{
  Error err = ERROR_INIT;
  if (lua_gettop(lstate) != 1) {
    api_set_error(&err, kErrorTypeValidation, "Expected 1 argument");
    goto exit_0;
  }
  if (!nlua_is_deferred_safe()) {
    return luaL_error(lstate, e_luv_api_disabled, "nvim_get_hl_id_by_name");
  }
    const String arg1 = nlua_pop_String(lstate, &err);
  if (ERROR_SET(&err)) {
    goto exit_0;
  }

  const Integer ret = nvim_get_hl_id_by_name(arg1);
  nlua_push_Integer(lstate, ret, true);
api_free_integer(ret);

  api_free_string(arg1);

exit_0:
  if (ERROR_SET(&err)) {
    luaL_where(lstate, 1);
    lua_pushstring(lstate, err.msg);
    api_clear_error(&err);
    lua_concat(lstate, 2);
    return lua_error(lstate);
  }

  return 1;
}

static int nlua_api_nvim__get_hl_defs(lua_State *lstate)
{
  Error err = ERROR_INIT;
  if (lua_gettop(lstate) != 1) {
    api_set_error(&err, kErrorTypeValidation, "Expected 1 argument");
    goto exit_0;
  }
  if (!nlua_is_deferred_safe()) {
    return luaL_error(lstate, e_luv_api_disabled, "nvim__get_hl_defs");
  }
    const Integer arg1 = nlua_pop_Integer(lstate, &err);
  if (ERROR_SET(&err)) {
    goto exit_0;
  }

  Arena arena = ARENA_EMPTY;
  const Dictionary ret = nvim__get_hl_defs(arg1, &arena, &err);
  nlua_push_Dictionary(lstate, ret, true);
arena_mem_free(arena_finish(&arena));

  api_free_integer(arg1);

exit_0:
  if (ERROR_SET(&err)) {
    luaL_where(lstate, 1);
    lua_pushstring(lstate, err.msg);
    api_clear_error(&err);
    lua_concat(lstate, 2);
    return lua_error(lstate);
  }

  return 1;
}

static int nlua_api_nvim_set_hl(lua_State *lstate)
{
  Error err = ERROR_INIT;
  if (lua_gettop(lstate) != 3) {
    api_set_error(&err, kErrorTypeValidation, "Expected 3 arguments");
    goto exit_0;
  }
  if (!nlua_is_deferred_safe()) {
    return luaL_error(lstate, e_luv_api_disabled, "nvim_set_hl");
  }
    KeyDict_highlight arg3 = { 0 }; nlua_pop_keydict(lstate, &arg3, KeyDict_highlight_get_field, &err);
  if (ERROR_SET(&err)) {
    goto exit_1;
  }

    const String arg2 = nlua_pop_String(lstate, &err);
  if (ERROR_SET(&err)) {
    goto exit_1;
  }

    const Integer arg1 = nlua_pop_Integer(lstate, &err);
  if (ERROR_SET(&err)) {
    goto exit_2;
  }

  nvim_set_hl(arg1, arg2, &arg3, &err);

  api_free_integer(arg1);
exit_2:
  api_free_string(arg2);
exit_1:
  api_free_keydict_highlight(&arg3);

exit_0:
  if (ERROR_SET(&err)) {
    luaL_where(lstate, 1);
    lua_pushstring(lstate, err.msg);
    api_clear_error(&err);
    lua_concat(lstate, 2);
    return lua_error(lstate);
  }

  return 0;
}

static int nlua_api_nvim_set_hl_ns(lua_State *lstate)
{
  Error err = ERROR_INIT;
  if (lua_gettop(lstate) != 1) {
    api_set_error(&err, kErrorTypeValidation, "Expected 1 argument");
    goto exit_0;
  }
  if (!nlua_is_deferred_safe()) {
    return luaL_error(lstate, e_luv_api_disabled, "nvim_set_hl_ns");
  }
    const Integer arg1 = nlua_pop_Integer(lstate, &err);
  if (ERROR_SET(&err)) {
    goto exit_0;
  }

  nvim_set_hl_ns(arg1, &err);

  api_free_integer(arg1);

exit_0:
  if (ERROR_SET(&err)) {
    luaL_where(lstate, 1);
    lua_pushstring(lstate, err.msg);
    api_clear_error(&err);
    lua_concat(lstate, 2);
    return lua_error(lstate);
  }

  return 0;
}

static int nlua_api_nvim_set_hl_ns_fast(lua_State *lstate)
{
  Error err = ERROR_INIT;
  if (lua_gettop(lstate) != 1) {
    api_set_error(&err, kErrorTypeValidation, "Expected 1 argument");
    goto exit_0;
  }
    const Integer arg1 = nlua_pop_Integer(lstate, &err);
  if (ERROR_SET(&err)) {
    goto exit_0;
  }

  nvim_set_hl_ns_fast(arg1, &err);

  api_free_integer(arg1);

exit_0:
  if (ERROR_SET(&err)) {
    luaL_where(lstate, 1);
    lua_pushstring(lstate, err.msg);
    api_clear_error(&err);
    lua_concat(lstate, 2);
    return lua_error(lstate);
  }

  return 0;
}

static int nlua_api_nvim_feedkeys(lua_State *lstate)
{
  Error err = ERROR_INIT;
  if (lua_gettop(lstate) != 3) {
    api_set_error(&err, kErrorTypeValidation, "Expected 3 arguments");
    goto exit_0;
  }
  if (!nlua_is_deferred_safe()) {
    return luaL_error(lstate, e_luv_api_disabled, "nvim_feedkeys");
  }
    const Boolean arg3 = nlua_pop_Boolean(lstate, &err);
  if (ERROR_SET(&err)) {
    goto exit_0;
  }

    const String arg2 = nlua_pop_String(lstate, &err);
  if (ERROR_SET(&err)) {
    goto exit_1;
  }

    const String arg1 = nlua_pop_String(lstate, &err);
  if (ERROR_SET(&err)) {
    goto exit_2;
  }

  nvim_feedkeys(arg1, arg2, arg3);

  api_free_string(arg1);
exit_2:
  api_free_string(arg2);
exit_1:
  api_free_boolean(arg3);

exit_0:
  if (ERROR_SET(&err)) {
    luaL_where(lstate, 1);
    lua_pushstring(lstate, err.msg);
    api_clear_error(&err);
    lua_concat(lstate, 2);
    return lua_error(lstate);
  }

  return 0;
}

static int nlua_api_nvim_input(lua_State *lstate)
{
  Error err = ERROR_INIT;
  if (lua_gettop(lstate) != 1) {
    api_set_error(&err, kErrorTypeValidation, "Expected 1 argument");
    goto exit_0;
  }
    const String arg1 = nlua_pop_String(lstate, &err);
  if (ERROR_SET(&err)) {
    goto exit_0;
  }

  const Integer ret = nvim_input(arg1);
  nlua_push_Integer(lstate, ret, true);
api_free_integer(ret);

  api_free_string(arg1);

exit_0:
  if (ERROR_SET(&err)) {
    luaL_where(lstate, 1);
    lua_pushstring(lstate, err.msg);
    api_clear_error(&err);
    lua_concat(lstate, 2);
    return lua_error(lstate);
  }

  return 1;
}

static int nlua_api_nvim_input_mouse(lua_State *lstate)
{
  Error err = ERROR_INIT;
  if (lua_gettop(lstate) != 6) {
    api_set_error(&err, kErrorTypeValidation, "Expected 6 arguments");
    goto exit_0;
  }
    const Integer arg6 = nlua_pop_Integer(lstate, &err);
  if (ERROR_SET(&err)) {
    goto exit_0;
  }

    const Integer arg5 = nlua_pop_Integer(lstate, &err);
  if (ERROR_SET(&err)) {
    goto exit_1;
  }

    const Integer arg4 = nlua_pop_Integer(lstate, &err);
  if (ERROR_SET(&err)) {
    goto exit_2;
  }

    const String arg3 = nlua_pop_String(lstate, &err);
  if (ERROR_SET(&err)) {
    goto exit_3;
  }

    const String arg2 = nlua_pop_String(lstate, &err);
  if (ERROR_SET(&err)) {
    goto exit_4;
  }

    const String arg1 = nlua_pop_String(lstate, &err);
  if (ERROR_SET(&err)) {
    goto exit_5;
  }

  nvim_input_mouse(arg1, arg2, arg3, arg4, arg5, arg6, &err);

  api_free_string(arg1);
exit_5:
  api_free_string(arg2);
exit_4:
  api_free_string(arg3);
exit_3:
  api_free_integer(arg4);
exit_2:
  api_free_integer(arg5);
exit_1:
  api_free_integer(arg6);

exit_0:
  if (ERROR_SET(&err)) {
    luaL_where(lstate, 1);
    lua_pushstring(lstate, err.msg);
    api_clear_error(&err);
    lua_concat(lstate, 2);
    return lua_error(lstate);
  }

  return 0;
}

static int nlua_api_nvim_replace_termcodes(lua_State *lstate)
{
  Error err = ERROR_INIT;
  if (lua_gettop(lstate) != 4) {
    api_set_error(&err, kErrorTypeValidation, "Expected 4 arguments");
    goto exit_0;
  }
  if (!nlua_is_deferred_safe()) {
    return luaL_error(lstate, e_luv_api_disabled, "nvim_replace_termcodes");
  }
    const Boolean arg4 = nlua_pop_Boolean(lstate, &err);
  if (ERROR_SET(&err)) {
    goto exit_0;
  }

    const Boolean arg3 = nlua_pop_Boolean(lstate, &err);
  if (ERROR_SET(&err)) {
    goto exit_1;
  }

    const Boolean arg2 = nlua_pop_Boolean(lstate, &err);
  if (ERROR_SET(&err)) {
    goto exit_2;
  }

    const String arg1 = nlua_pop_String(lstate, &err);
  if (ERROR_SET(&err)) {
    goto exit_3;
  }

  const String ret = nvim_replace_termcodes(arg1, arg2, arg3, arg4);
  nlua_push_String(lstate, ret, true);
api_free_string(ret);

  api_free_string(arg1);
exit_3:
  api_free_boolean(arg2);
exit_2:
  api_free_boolean(arg3);
exit_1:
  api_free_boolean(arg4);

exit_0:
  if (ERROR_SET(&err)) {
    luaL_where(lstate, 1);
    lua_pushstring(lstate, err.msg);
    api_clear_error(&err);
    lua_concat(lstate, 2);
    return lua_error(lstate);
  }

  return 1;
}

static int nlua_api_nvim_notify(lua_State *lstate)
{
  Error err = ERROR_INIT;
  if (lua_gettop(lstate) != 3) {
    api_set_error(&err, kErrorTypeValidation, "Expected 3 arguments");
    goto exit_0;
  }
  if (!nlua_is_deferred_safe()) {
    return luaL_error(lstate, e_luv_api_disabled, "nvim_notify");
  }
    const Dictionary arg3 = nlua_pop_Dictionary(lstate, false, &err);
  if (ERROR_SET(&err)) {
    goto exit_0;
  }

    const Integer arg2 = nlua_pop_Integer(lstate, &err);
  if (ERROR_SET(&err)) {
    goto exit_1;
  }

    const String arg1 = nlua_pop_String(lstate, &err);
  if (ERROR_SET(&err)) {
    goto exit_2;
  }

  const Object ret = nvim_notify(arg1, arg2, arg3, &err);
  nlua_push_Object(lstate, ret, true);
api_free_object(ret);

  api_free_string(arg1);
exit_2:
  api_free_integer(arg2);
exit_1:
  api_free_dictionary(arg3);

exit_0:
  if (ERROR_SET(&err)) {
    luaL_where(lstate, 1);
    lua_pushstring(lstate, err.msg);
    api_clear_error(&err);
    lua_concat(lstate, 2);
    return lua_error(lstate);
  }

  return 1;
}

static int nlua_api_nvim_strwidth(lua_State *lstate)
{
  Error err = ERROR_INIT;
  if (lua_gettop(lstate) != 1) {
    api_set_error(&err, kErrorTypeValidation, "Expected 1 argument");
    goto exit_0;
  }
  if (!nlua_is_deferred_safe()) {
    return luaL_error(lstate, e_luv_api_disabled, "nvim_strwidth");
  }
    const String arg1 = nlua_pop_String(lstate, &err);
  if (ERROR_SET(&err)) {
    goto exit_0;
  }

  const Integer ret = nvim_strwidth(arg1, &err);
  nlua_push_Integer(lstate, ret, true);
api_free_integer(ret);

  api_free_string(arg1);

exit_0:
  if (ERROR_SET(&err)) {
    luaL_where(lstate, 1);
    lua_pushstring(lstate, err.msg);
    api_clear_error(&err);
    lua_concat(lstate, 2);
    return lua_error(lstate);
  }

  return 1;
}

static int nlua_api_nvim_list_runtime_paths(lua_State *lstate)
{
  Error err = ERROR_INIT;
  if (lua_gettop(lstate) != 0) {
    api_set_error(&err, kErrorTypeValidation, "Expected 0 arguments");
    goto exit_0;
  }
  if (!nlua_is_deferred_safe()) {
    return luaL_error(lstate, e_luv_api_disabled, "nvim_list_runtime_paths");
  }
  const ArrayOf(String) ret = nvim_list_runtime_paths(&err);
  nlua_push_Array(lstate, ret, true);
api_free_array(ret);


exit_0:
  if (ERROR_SET(&err)) {
    luaL_where(lstate, 1);
    lua_pushstring(lstate, err.msg);
    api_clear_error(&err);
    lua_concat(lstate, 2);
    return lua_error(lstate);
  }

  return 1;
}

static int nlua_api_nvim__runtime_inspect(lua_State *lstate)
{
  Error err = ERROR_INIT;
  if (lua_gettop(lstate) != 0) {
    api_set_error(&err, kErrorTypeValidation, "Expected 0 arguments");
    goto exit_0;
  }
  if (!nlua_is_deferred_safe()) {
    return luaL_error(lstate, e_luv_api_disabled, "nvim__runtime_inspect");
  }
  const Array ret = nvim__runtime_inspect();
  nlua_push_Array(lstate, ret, true);
api_free_array(ret);


exit_0:
  if (ERROR_SET(&err)) {
    luaL_where(lstate, 1);
    lua_pushstring(lstate, err.msg);
    api_clear_error(&err);
    lua_concat(lstate, 2);
    return lua_error(lstate);
  }

  return 1;
}

static int nlua_api_nvim_get_runtime_file(lua_State *lstate)
{
  Error err = ERROR_INIT;
  if (lua_gettop(lstate) != 2) {
    api_set_error(&err, kErrorTypeValidation, "Expected 2 arguments");
    goto exit_0;
  }
    const Boolean arg2 = nlua_pop_Boolean(lstate, &err);
  if (ERROR_SET(&err)) {
    goto exit_0;
  }

    const String arg1 = nlua_pop_String(lstate, &err);
  if (ERROR_SET(&err)) {
    goto exit_1;
  }

  const ArrayOf(String) ret = nvim_get_runtime_file(arg1, arg2, &err);
  nlua_push_Array(lstate, ret, true);
api_free_array(ret);

  api_free_string(arg1);
exit_1:
  api_free_boolean(arg2);

exit_0:
  if (ERROR_SET(&err)) {
    luaL_where(lstate, 1);
    lua_pushstring(lstate, err.msg);
    api_clear_error(&err);
    lua_concat(lstate, 2);
    return lua_error(lstate);
  }

  return 1;
}

static int nlua_api_nvim__get_lib_dir(lua_State *lstate)
{
  Error err = ERROR_INIT;
  if (lua_gettop(lstate) != 0) {
    api_set_error(&err, kErrorTypeValidation, "Expected 0 arguments");
    goto exit_0;
  }
  if (!nlua_is_deferred_safe()) {
    return luaL_error(lstate, e_luv_api_disabled, "nvim__get_lib_dir");
  }
  const String ret = nvim__get_lib_dir();
  nlua_push_String(lstate, ret, true);
api_free_string(ret);


exit_0:
  if (ERROR_SET(&err)) {
    luaL_where(lstate, 1);
    lua_pushstring(lstate, err.msg);
    api_clear_error(&err);
    lua_concat(lstate, 2);
    return lua_error(lstate);
  }

  return 1;
}

static int nlua_api_nvim__get_runtime(lua_State *lstate)
{
  Error err = ERROR_INIT;
  if (lua_gettop(lstate) != 3) {
    api_set_error(&err, kErrorTypeValidation, "Expected 3 arguments");
    goto exit_0;
  }
    KeyDict_runtime arg3 = { 0 }; nlua_pop_keydict(lstate, &arg3, KeyDict_runtime_get_field, &err);
  if (ERROR_SET(&err)) {
    goto exit_1;
  }

    const Boolean arg2 = nlua_pop_Boolean(lstate, &err);
  if (ERROR_SET(&err)) {
    goto exit_1;
  }

    const Array arg1 = nlua_pop_Array(lstate, &err);
  if (ERROR_SET(&err)) {
    goto exit_2;
  }

  const ArrayOf(String) ret = nvim__get_runtime(arg1, arg2, &arg3, &err);
  nlua_push_Array(lstate, ret, true);
api_free_array(ret);

  api_free_array(arg1);
exit_2:
  api_free_boolean(arg2);
exit_1:
  api_free_keydict_runtime(&arg3);

exit_0:
  if (ERROR_SET(&err)) {
    luaL_where(lstate, 1);
    lua_pushstring(lstate, err.msg);
    api_clear_error(&err);
    lua_concat(lstate, 2);
    return lua_error(lstate);
  }

  return 1;
}

static int nlua_api_nvim_set_current_dir(lua_State *lstate)
{
  Error err = ERROR_INIT;
  if (lua_gettop(lstate) != 1) {
    api_set_error(&err, kErrorTypeValidation, "Expected 1 argument");
    goto exit_0;
  }
  if (!nlua_is_deferred_safe()) {
    return luaL_error(lstate, e_luv_api_disabled, "nvim_set_current_dir");
  }
    const String arg1 = nlua_pop_String(lstate, &err);
  if (ERROR_SET(&err)) {
    goto exit_0;
  }

  nvim_set_current_dir(arg1, &err);

  api_free_string(arg1);

exit_0:
  if (ERROR_SET(&err)) {
    luaL_where(lstate, 1);
    lua_pushstring(lstate, err.msg);
    api_clear_error(&err);
    lua_concat(lstate, 2);
    return lua_error(lstate);
  }

  return 0;
}

static int nlua_api_nvim_get_current_line(lua_State *lstate)
{
  Error err = ERROR_INIT;
  if (lua_gettop(lstate) != 0) {
    api_set_error(&err, kErrorTypeValidation, "Expected 0 arguments");
    goto exit_0;
  }
  if (!nlua_is_deferred_safe()) {
    return luaL_error(lstate, e_luv_api_disabled, "nvim_get_current_line");
  }
  const String ret = nvim_get_current_line(&err);
  nlua_push_String(lstate, ret, true);
api_free_string(ret);


exit_0:
  if (ERROR_SET(&err)) {
    luaL_where(lstate, 1);
    lua_pushstring(lstate, err.msg);
    api_clear_error(&err);
    lua_concat(lstate, 2);
    return lua_error(lstate);
  }

  return 1;
}

static int nlua_api_nvim_set_current_line(lua_State *lstate)
{
  Error err = ERROR_INIT;
  if (lua_gettop(lstate) != 1) {
    api_set_error(&err, kErrorTypeValidation, "Expected 1 argument");
    goto exit_0;
  }
  if (!nlua_is_deferred_safe()) {
    return luaL_error(lstate, e_luv_api_disabled, "nvim_set_current_line");
  }
  if (textlock != 0) {
    api_set_error(&err, kErrorTypeException, "%s", e_textlock);
    goto exit_0;
  }
    const String arg1 = nlua_pop_String(lstate, &err);
  if (ERROR_SET(&err)) {
    goto exit_0;
  }

  nvim_set_current_line(arg1, &err);

  api_free_string(arg1);

exit_0:
  if (ERROR_SET(&err)) {
    luaL_where(lstate, 1);
    lua_pushstring(lstate, err.msg);
    api_clear_error(&err);
    lua_concat(lstate, 2);
    return lua_error(lstate);
  }

  return 0;
}

static int nlua_api_nvim_del_current_line(lua_State *lstate)
{
  Error err = ERROR_INIT;
  if (lua_gettop(lstate) != 0) {
    api_set_error(&err, kErrorTypeValidation, "Expected 0 arguments");
    goto exit_0;
  }
  if (!nlua_is_deferred_safe()) {
    return luaL_error(lstate, e_luv_api_disabled, "nvim_del_current_line");
  }
  if (textlock != 0) {
    api_set_error(&err, kErrorTypeException, "%s", e_textlock);
    goto exit_0;
  }
  nvim_del_current_line(&err);


exit_0:
  if (ERROR_SET(&err)) {
    luaL_where(lstate, 1);
    lua_pushstring(lstate, err.msg);
    api_clear_error(&err);
    lua_concat(lstate, 2);
    return lua_error(lstate);
  }

  return 0;
}

static int nlua_api_nvim_get_var(lua_State *lstate)
{
  Error err = ERROR_INIT;
  if (lua_gettop(lstate) != 1) {
    api_set_error(&err, kErrorTypeValidation, "Expected 1 argument");
    goto exit_0;
  }
  if (!nlua_is_deferred_safe()) {
    return luaL_error(lstate, e_luv_api_disabled, "nvim_get_var");
  }
    const String arg1 = nlua_pop_String(lstate, &err);
  if (ERROR_SET(&err)) {
    goto exit_0;
  }

  const Object ret = nvim_get_var(arg1, &err);
  nlua_push_Object(lstate, ret, true);
api_free_object(ret);

  api_free_string(arg1);

exit_0:
  if (ERROR_SET(&err)) {
    luaL_where(lstate, 1);
    lua_pushstring(lstate, err.msg);
    api_clear_error(&err);
    lua_concat(lstate, 2);
    return lua_error(lstate);
  }

  return 1;
}

static int nlua_api_nvim_set_var(lua_State *lstate)
{
  Error err = ERROR_INIT;
  if (lua_gettop(lstate) != 2) {
    api_set_error(&err, kErrorTypeValidation, "Expected 2 arguments");
    goto exit_0;
  }
  if (!nlua_is_deferred_safe()) {
    return luaL_error(lstate, e_luv_api_disabled, "nvim_set_var");
  }
    const Object arg2 = nlua_pop_Object(lstate, true, &err);
  if (ERROR_SET(&err)) {
    goto exit_0;
  }

    const String arg1 = nlua_pop_String(lstate, &err);
  if (ERROR_SET(&err)) {
    goto exit_1;
  }

  nvim_set_var(arg1, arg2, &err);

  api_free_string(arg1);
exit_1:
  api_free_object(arg2);

exit_0:
  if (ERROR_SET(&err)) {
    luaL_where(lstate, 1);
    lua_pushstring(lstate, err.msg);
    api_clear_error(&err);
    lua_concat(lstate, 2);
    return lua_error(lstate);
  }

  return 0;
}

static int nlua_api_nvim_del_var(lua_State *lstate)
{
  Error err = ERROR_INIT;
  if (lua_gettop(lstate) != 1) {
    api_set_error(&err, kErrorTypeValidation, "Expected 1 argument");
    goto exit_0;
  }
  if (!nlua_is_deferred_safe()) {
    return luaL_error(lstate, e_luv_api_disabled, "nvim_del_var");
  }
    const String arg1 = nlua_pop_String(lstate, &err);
  if (ERROR_SET(&err)) {
    goto exit_0;
  }

  nvim_del_var(arg1, &err);

  api_free_string(arg1);

exit_0:
  if (ERROR_SET(&err)) {
    luaL_where(lstate, 1);
    lua_pushstring(lstate, err.msg);
    api_clear_error(&err);
    lua_concat(lstate, 2);
    return lua_error(lstate);
  }

  return 0;
}

static int nlua_api_nvim_get_vvar(lua_State *lstate)
{
  Error err = ERROR_INIT;
  if (lua_gettop(lstate) != 1) {
    api_set_error(&err, kErrorTypeValidation, "Expected 1 argument");
    goto exit_0;
  }
  if (!nlua_is_deferred_safe()) {
    return luaL_error(lstate, e_luv_api_disabled, "nvim_get_vvar");
  }
    const String arg1 = nlua_pop_String(lstate, &err);
  if (ERROR_SET(&err)) {
    goto exit_0;
  }

  const Object ret = nvim_get_vvar(arg1, &err);
  nlua_push_Object(lstate, ret, true);
api_free_object(ret);

  api_free_string(arg1);

exit_0:
  if (ERROR_SET(&err)) {
    luaL_where(lstate, 1);
    lua_pushstring(lstate, err.msg);
    api_clear_error(&err);
    lua_concat(lstate, 2);
    return lua_error(lstate);
  }

  return 1;
}

static int nlua_api_nvim_set_vvar(lua_State *lstate)
{
  Error err = ERROR_INIT;
  if (lua_gettop(lstate) != 2) {
    api_set_error(&err, kErrorTypeValidation, "Expected 2 arguments");
    goto exit_0;
  }
  if (!nlua_is_deferred_safe()) {
    return luaL_error(lstate, e_luv_api_disabled, "nvim_set_vvar");
  }
    const Object arg2 = nlua_pop_Object(lstate, true, &err);
  if (ERROR_SET(&err)) {
    goto exit_0;
  }

    const String arg1 = nlua_pop_String(lstate, &err);
  if (ERROR_SET(&err)) {
    goto exit_1;
  }

  nvim_set_vvar(arg1, arg2, &err);

  api_free_string(arg1);
exit_1:
  api_free_object(arg2);

exit_0:
  if (ERROR_SET(&err)) {
    luaL_where(lstate, 1);
    lua_pushstring(lstate, err.msg);
    api_clear_error(&err);
    lua_concat(lstate, 2);
    return lua_error(lstate);
  }

  return 0;
}

static int nlua_api_nvim_echo(lua_State *lstate)
{
  Error err = ERROR_INIT;
  if (lua_gettop(lstate) != 3) {
    api_set_error(&err, kErrorTypeValidation, "Expected 3 arguments");
    goto exit_0;
  }
  if (!nlua_is_deferred_safe()) {
    return luaL_error(lstate, e_luv_api_disabled, "nvim_echo");
  }
    const Dictionary arg3 = nlua_pop_Dictionary(lstate, false, &err);
  if (ERROR_SET(&err)) {
    goto exit_0;
  }

    const Boolean arg2 = nlua_pop_Boolean(lstate, &err);
  if (ERROR_SET(&err)) {
    goto exit_1;
  }

    const Array arg1 = nlua_pop_Array(lstate, &err);
  if (ERROR_SET(&err)) {
    goto exit_2;
  }

  nvim_echo(arg1, arg2, arg3, &err);

  api_free_array(arg1);
exit_2:
  api_free_boolean(arg2);
exit_1:
  api_free_dictionary(arg3);

exit_0:
  if (ERROR_SET(&err)) {
    luaL_where(lstate, 1);
    lua_pushstring(lstate, err.msg);
    api_clear_error(&err);
    lua_concat(lstate, 2);
    return lua_error(lstate);
  }

  return 0;
}

static int nlua_api_nvim_out_write(lua_State *lstate)
{
  Error err = ERROR_INIT;
  if (lua_gettop(lstate) != 1) {
    api_set_error(&err, kErrorTypeValidation, "Expected 1 argument");
    goto exit_0;
  }
  if (!nlua_is_deferred_safe()) {
    return luaL_error(lstate, e_luv_api_disabled, "nvim_out_write");
  }
    const String arg1 = nlua_pop_String(lstate, &err);
  if (ERROR_SET(&err)) {
    goto exit_0;
  }

  nvim_out_write(arg1);

  api_free_string(arg1);

exit_0:
  if (ERROR_SET(&err)) {
    luaL_where(lstate, 1);
    lua_pushstring(lstate, err.msg);
    api_clear_error(&err);
    lua_concat(lstate, 2);
    return lua_error(lstate);
  }

  return 0;
}

static int nlua_api_nvim_err_write(lua_State *lstate)
{
  Error err = ERROR_INIT;
  if (lua_gettop(lstate) != 1) {
    api_set_error(&err, kErrorTypeValidation, "Expected 1 argument");
    goto exit_0;
  }
  if (!nlua_is_deferred_safe()) {
    return luaL_error(lstate, e_luv_api_disabled, "nvim_err_write");
  }
    const String arg1 = nlua_pop_String(lstate, &err);
  if (ERROR_SET(&err)) {
    goto exit_0;
  }

  nvim_err_write(arg1);

  api_free_string(arg1);

exit_0:
  if (ERROR_SET(&err)) {
    luaL_where(lstate, 1);
    lua_pushstring(lstate, err.msg);
    api_clear_error(&err);
    lua_concat(lstate, 2);
    return lua_error(lstate);
  }

  return 0;
}

static int nlua_api_nvim_err_writeln(lua_State *lstate)
{
  Error err = ERROR_INIT;
  if (lua_gettop(lstate) != 1) {
    api_set_error(&err, kErrorTypeValidation, "Expected 1 argument");
    goto exit_0;
  }
  if (!nlua_is_deferred_safe()) {
    return luaL_error(lstate, e_luv_api_disabled, "nvim_err_writeln");
  }
    const String arg1 = nlua_pop_String(lstate, &err);
  if (ERROR_SET(&err)) {
    goto exit_0;
  }

  nvim_err_writeln(arg1);

  api_free_string(arg1);

exit_0:
  if (ERROR_SET(&err)) {
    luaL_where(lstate, 1);
    lua_pushstring(lstate, err.msg);
    api_clear_error(&err);
    lua_concat(lstate, 2);
    return lua_error(lstate);
  }

  return 0;
}

static int nlua_api_nvim_list_bufs(lua_State *lstate)
{
  Error err = ERROR_INIT;
  if (lua_gettop(lstate) != 0) {
    api_set_error(&err, kErrorTypeValidation, "Expected 0 arguments");
    goto exit_0;
  }
  if (!nlua_is_deferred_safe()) {
    return luaL_error(lstate, e_luv_api_disabled, "nvim_list_bufs");
  }
  const ArrayOf(Buffer) ret = nvim_list_bufs();
  nlua_push_Array(lstate, ret, true);
api_free_array(ret);


exit_0:
  if (ERROR_SET(&err)) {
    luaL_where(lstate, 1);
    lua_pushstring(lstate, err.msg);
    api_clear_error(&err);
    lua_concat(lstate, 2);
    return lua_error(lstate);
  }

  return 1;
}

static int nlua_api_nvim_get_current_buf(lua_State *lstate)
{
  Error err = ERROR_INIT;
  if (lua_gettop(lstate) != 0) {
    api_set_error(&err, kErrorTypeValidation, "Expected 0 arguments");
    goto exit_0;
  }
  if (!nlua_is_deferred_safe()) {
    return luaL_error(lstate, e_luv_api_disabled, "nvim_get_current_buf");
  }
  const Buffer ret = nvim_get_current_buf();
  nlua_push_Buffer(lstate, ret, true);
api_free_buffer(ret);


exit_0:
  if (ERROR_SET(&err)) {
    luaL_where(lstate, 1);
    lua_pushstring(lstate, err.msg);
    api_clear_error(&err);
    lua_concat(lstate, 2);
    return lua_error(lstate);
  }

  return 1;
}

static int nlua_api_nvim_set_current_buf(lua_State *lstate)
{
  Error err = ERROR_INIT;
  if (lua_gettop(lstate) != 1) {
    api_set_error(&err, kErrorTypeValidation, "Expected 1 argument");
    goto exit_0;
  }
  if (!nlua_is_deferred_safe()) {
    return luaL_error(lstate, e_luv_api_disabled, "nvim_set_current_buf");
  }
  if (textlock != 0) {
    api_set_error(&err, kErrorTypeException, "%s", e_textlock);
    goto exit_0;
  }
    const Buffer arg1 = nlua_pop_Buffer(lstate, &err);
  if (ERROR_SET(&err)) {
    goto exit_0;
  }

  nvim_set_current_buf(arg1, &err);

  api_free_buffer(arg1);

exit_0:
  if (ERROR_SET(&err)) {
    luaL_where(lstate, 1);
    lua_pushstring(lstate, err.msg);
    api_clear_error(&err);
    lua_concat(lstate, 2);
    return lua_error(lstate);
  }

  return 0;
}

static int nlua_api_nvim_list_wins(lua_State *lstate)
{
  Error err = ERROR_INIT;
  if (lua_gettop(lstate) != 0) {
    api_set_error(&err, kErrorTypeValidation, "Expected 0 arguments");
    goto exit_0;
  }
  if (!nlua_is_deferred_safe()) {
    return luaL_error(lstate, e_luv_api_disabled, "nvim_list_wins");
  }
  const ArrayOf(Window) ret = nvim_list_wins();
  nlua_push_Array(lstate, ret, true);
api_free_array(ret);


exit_0:
  if (ERROR_SET(&err)) {
    luaL_where(lstate, 1);
    lua_pushstring(lstate, err.msg);
    api_clear_error(&err);
    lua_concat(lstate, 2);
    return lua_error(lstate);
  }

  return 1;
}

static int nlua_api_nvim_get_current_win(lua_State *lstate)
{
  Error err = ERROR_INIT;
  if (lua_gettop(lstate) != 0) {
    api_set_error(&err, kErrorTypeValidation, "Expected 0 arguments");
    goto exit_0;
  }
  if (!nlua_is_deferred_safe()) {
    return luaL_error(lstate, e_luv_api_disabled, "nvim_get_current_win");
  }
  const Window ret = nvim_get_current_win();
  nlua_push_Window(lstate, ret, true);
api_free_window(ret);


exit_0:
  if (ERROR_SET(&err)) {
    luaL_where(lstate, 1);
    lua_pushstring(lstate, err.msg);
    api_clear_error(&err);
    lua_concat(lstate, 2);
    return lua_error(lstate);
  }

  return 1;
}

static int nlua_api_nvim_set_current_win(lua_State *lstate)
{
  Error err = ERROR_INIT;
  if (lua_gettop(lstate) != 1) {
    api_set_error(&err, kErrorTypeValidation, "Expected 1 argument");
    goto exit_0;
  }
  if (!nlua_is_deferred_safe()) {
    return luaL_error(lstate, e_luv_api_disabled, "nvim_set_current_win");
  }
  if (textlock != 0) {
    api_set_error(&err, kErrorTypeException, "%s", e_textlock);
    goto exit_0;
  }
    const Window arg1 = nlua_pop_Window(lstate, &err);
  if (ERROR_SET(&err)) {
    goto exit_0;
  }

  nvim_set_current_win(arg1, &err);

  api_free_window(arg1);

exit_0:
  if (ERROR_SET(&err)) {
    luaL_where(lstate, 1);
    lua_pushstring(lstate, err.msg);
    api_clear_error(&err);
    lua_concat(lstate, 2);
    return lua_error(lstate);
  }

  return 0;
}

static int nlua_api_nvim_create_buf(lua_State *lstate)
{
  Error err = ERROR_INIT;
  if (lua_gettop(lstate) != 2) {
    api_set_error(&err, kErrorTypeValidation, "Expected 2 arguments");
    goto exit_0;
  }
  if (!nlua_is_deferred_safe()) {
    return luaL_error(lstate, e_luv_api_disabled, "nvim_create_buf");
  }
    const Boolean arg2 = nlua_pop_Boolean(lstate, &err);
  if (ERROR_SET(&err)) {
    goto exit_0;
  }

    const Boolean arg1 = nlua_pop_Boolean(lstate, &err);
  if (ERROR_SET(&err)) {
    goto exit_1;
  }

  const Buffer ret = nvim_create_buf(arg1, arg2, &err);
  nlua_push_Buffer(lstate, ret, true);
api_free_buffer(ret);

  api_free_boolean(arg1);
exit_1:
  api_free_boolean(arg2);

exit_0:
  if (ERROR_SET(&err)) {
    luaL_where(lstate, 1);
    lua_pushstring(lstate, err.msg);
    api_clear_error(&err);
    lua_concat(lstate, 2);
    return lua_error(lstate);
  }

  return 1;
}

static int nlua_api_nvim_open_term(lua_State *lstate)
{
  Error err = ERROR_INIT;
  if (lua_gettop(lstate) != 2) {
    api_set_error(&err, kErrorTypeValidation, "Expected 2 arguments");
    goto exit_0;
  }
  if (!nlua_is_deferred_safe()) {
    return luaL_error(lstate, e_luv_api_disabled, "nvim_open_term");
  }
    const DictionaryOf(LuaRef) arg2 = nlua_pop_Dictionary(lstate, true, &err);
  if (ERROR_SET(&err)) {
    goto exit_0;
  }

    const Buffer arg1 = nlua_pop_Buffer(lstate, &err);
  if (ERROR_SET(&err)) {
    goto exit_1;
  }

  const Integer ret = nvim_open_term(arg1, arg2, &err);
  nlua_push_Integer(lstate, ret, true);
api_free_integer(ret);

  api_free_buffer(arg1);
exit_1:
  api_free_dictionary(arg2);

exit_0:
  if (ERROR_SET(&err)) {
    luaL_where(lstate, 1);
    lua_pushstring(lstate, err.msg);
    api_clear_error(&err);
    lua_concat(lstate, 2);
    return lua_error(lstate);
  }

  return 1;
}

static int nlua_api_nvim_chan_send(lua_State *lstate)
{
  Error err = ERROR_INIT;
  if (lua_gettop(lstate) != 2) {
    api_set_error(&err, kErrorTypeValidation, "Expected 2 arguments");
    goto exit_0;
  }
  if (!nlua_is_deferred_safe()) {
    return luaL_error(lstate, e_luv_api_disabled, "nvim_chan_send");
  }
    const String arg2 = nlua_pop_String(lstate, &err);
  if (ERROR_SET(&err)) {
    goto exit_0;
  }

    const Integer arg1 = nlua_pop_Integer(lstate, &err);
  if (ERROR_SET(&err)) {
    goto exit_1;
  }

  nvim_chan_send(arg1, arg2, &err);

  api_free_integer(arg1);
exit_1:
  api_free_string(arg2);

exit_0:
  if (ERROR_SET(&err)) {
    luaL_where(lstate, 1);
    lua_pushstring(lstate, err.msg);
    api_clear_error(&err);
    lua_concat(lstate, 2);
    return lua_error(lstate);
  }

  return 0;
}

static int nlua_api_nvim_list_tabpages(lua_State *lstate)
{
  Error err = ERROR_INIT;
  if (lua_gettop(lstate) != 0) {
    api_set_error(&err, kErrorTypeValidation, "Expected 0 arguments");
    goto exit_0;
  }
  if (!nlua_is_deferred_safe()) {
    return luaL_error(lstate, e_luv_api_disabled, "nvim_list_tabpages");
  }
  const ArrayOf(Tabpage) ret = nvim_list_tabpages();
  nlua_push_Array(lstate, ret, true);
api_free_array(ret);


exit_0:
  if (ERROR_SET(&err)) {
    luaL_where(lstate, 1);
    lua_pushstring(lstate, err.msg);
    api_clear_error(&err);
    lua_concat(lstate, 2);
    return lua_error(lstate);
  }

  return 1;
}

static int nlua_api_nvim_get_current_tabpage(lua_State *lstate)
{
  Error err = ERROR_INIT;
  if (lua_gettop(lstate) != 0) {
    api_set_error(&err, kErrorTypeValidation, "Expected 0 arguments");
    goto exit_0;
  }
  if (!nlua_is_deferred_safe()) {
    return luaL_error(lstate, e_luv_api_disabled, "nvim_get_current_tabpage");
  }
  const Tabpage ret = nvim_get_current_tabpage();
  nlua_push_Tabpage(lstate, ret, true);
api_free_tabpage(ret);


exit_0:
  if (ERROR_SET(&err)) {
    luaL_where(lstate, 1);
    lua_pushstring(lstate, err.msg);
    api_clear_error(&err);
    lua_concat(lstate, 2);
    return lua_error(lstate);
  }

  return 1;
}

static int nlua_api_nvim_set_current_tabpage(lua_State *lstate)
{
  Error err = ERROR_INIT;
  if (lua_gettop(lstate) != 1) {
    api_set_error(&err, kErrorTypeValidation, "Expected 1 argument");
    goto exit_0;
  }
  if (!nlua_is_deferred_safe()) {
    return luaL_error(lstate, e_luv_api_disabled, "nvim_set_current_tabpage");
  }
  if (textlock != 0) {
    api_set_error(&err, kErrorTypeException, "%s", e_textlock);
    goto exit_0;
  }
    const Tabpage arg1 = nlua_pop_Tabpage(lstate, &err);
  if (ERROR_SET(&err)) {
    goto exit_0;
  }

  nvim_set_current_tabpage(arg1, &err);

  api_free_tabpage(arg1);

exit_0:
  if (ERROR_SET(&err)) {
    luaL_where(lstate, 1);
    lua_pushstring(lstate, err.msg);
    api_clear_error(&err);
    lua_concat(lstate, 2);
    return lua_error(lstate);
  }

  return 0;
}

static int nlua_api_nvim_paste(lua_State *lstate)
{
  Error err = ERROR_INIT;
  if (lua_gettop(lstate) != 3) {
    api_set_error(&err, kErrorTypeValidation, "Expected 3 arguments");
    goto exit_0;
  }
  if (!nlua_is_deferred_safe()) {
    return luaL_error(lstate, e_luv_api_disabled, "nvim_paste");
  }
  if (textlock != 0) {
    api_set_error(&err, kErrorTypeException, "%s", e_textlock);
    goto exit_0;
  }
    const Integer arg3 = nlua_pop_Integer(lstate, &err);
  if (ERROR_SET(&err)) {
    goto exit_0;
  }

    const Boolean arg2 = nlua_pop_Boolean(lstate, &err);
  if (ERROR_SET(&err)) {
    goto exit_1;
  }

    const String arg1 = nlua_pop_String(lstate, &err);
  if (ERROR_SET(&err)) {
    goto exit_2;
  }

  const Boolean ret = nvim_paste(arg1, arg2, arg3, &err);
  nlua_push_Boolean(lstate, ret, true);
api_free_boolean(ret);

  api_free_string(arg1);
exit_2:
  api_free_boolean(arg2);
exit_1:
  api_free_integer(arg3);

exit_0:
  if (ERROR_SET(&err)) {
    luaL_where(lstate, 1);
    lua_pushstring(lstate, err.msg);
    api_clear_error(&err);
    lua_concat(lstate, 2);
    return lua_error(lstate);
  }

  return 1;
}

static int nlua_api_nvim_put(lua_State *lstate)
{
  Error err = ERROR_INIT;
  if (lua_gettop(lstate) != 4) {
    api_set_error(&err, kErrorTypeValidation, "Expected 4 arguments");
    goto exit_0;
  }
  if (!nlua_is_deferred_safe()) {
    return luaL_error(lstate, e_luv_api_disabled, "nvim_put");
  }
  if (textlock != 0) {
    api_set_error(&err, kErrorTypeException, "%s", e_textlock);
    goto exit_0;
  }
    const Boolean arg4 = nlua_pop_Boolean(lstate, &err);
  if (ERROR_SET(&err)) {
    goto exit_0;
  }

    const Boolean arg3 = nlua_pop_Boolean(lstate, &err);
  if (ERROR_SET(&err)) {
    goto exit_1;
  }

    const String arg2 = nlua_pop_String(lstate, &err);
  if (ERROR_SET(&err)) {
    goto exit_2;
  }

    const ArrayOf(String) arg1 = nlua_pop_Array(lstate, &err);
  if (ERROR_SET(&err)) {
    goto exit_3;
  }

  nvim_put(arg1, arg2, arg3, arg4, &err);

  api_free_array(arg1);
exit_3:
  api_free_string(arg2);
exit_2:
  api_free_boolean(arg3);
exit_1:
  api_free_boolean(arg4);

exit_0:
  if (ERROR_SET(&err)) {
    luaL_where(lstate, 1);
    lua_pushstring(lstate, err.msg);
    api_clear_error(&err);
    lua_concat(lstate, 2);
    return lua_error(lstate);
  }

  return 0;
}

static int nlua_api_nvim_get_color_by_name(lua_State *lstate)
{
  Error err = ERROR_INIT;
  if (lua_gettop(lstate) != 1) {
    api_set_error(&err, kErrorTypeValidation, "Expected 1 argument");
    goto exit_0;
  }
  if (!nlua_is_deferred_safe()) {
    return luaL_error(lstate, e_luv_api_disabled, "nvim_get_color_by_name");
  }
    const String arg1 = nlua_pop_String(lstate, &err);
  if (ERROR_SET(&err)) {
    goto exit_0;
  }

  const Integer ret = nvim_get_color_by_name(arg1);
  nlua_push_Integer(lstate, ret, true);
api_free_integer(ret);

  api_free_string(arg1);

exit_0:
  if (ERROR_SET(&err)) {
    luaL_where(lstate, 1);
    lua_pushstring(lstate, err.msg);
    api_clear_error(&err);
    lua_concat(lstate, 2);
    return lua_error(lstate);
  }

  return 1;
}

static int nlua_api_nvim_get_color_map(lua_State *lstate)
{
  Error err = ERROR_INIT;
  if (lua_gettop(lstate) != 0) {
    api_set_error(&err, kErrorTypeValidation, "Expected 0 arguments");
    goto exit_0;
  }
  if (!nlua_is_deferred_safe()) {
    return luaL_error(lstate, e_luv_api_disabled, "nvim_get_color_map");
  }
  const Dictionary ret = nvim_get_color_map();
  nlua_push_Dictionary(lstate, ret, true);
api_free_dictionary(ret);


exit_0:
  if (ERROR_SET(&err)) {
    luaL_where(lstate, 1);
    lua_pushstring(lstate, err.msg);
    api_clear_error(&err);
    lua_concat(lstate, 2);
    return lua_error(lstate);
  }

  return 1;
}

static int nlua_api_nvim_get_context(lua_State *lstate)
{
  Error err = ERROR_INIT;
  if (lua_gettop(lstate) != 1) {
    api_set_error(&err, kErrorTypeValidation, "Expected 1 argument");
    goto exit_0;
  }
  if (!nlua_is_deferred_safe()) {
    return luaL_error(lstate, e_luv_api_disabled, "nvim_get_context");
  }
    KeyDict_context arg1 = { 0 }; nlua_pop_keydict(lstate, &arg1, KeyDict_context_get_field, &err);
  if (ERROR_SET(&err)) {
    goto exit_1;
  }

  const Dictionary ret = nvim_get_context(&arg1, &err);
  nlua_push_Dictionary(lstate, ret, true);
api_free_dictionary(ret);

exit_1:
  api_free_keydict_context(&arg1);

exit_0:
  if (ERROR_SET(&err)) {
    luaL_where(lstate, 1);
    lua_pushstring(lstate, err.msg);
    api_clear_error(&err);
    lua_concat(lstate, 2);
    return lua_error(lstate);
  }

  return 1;
}

static int nlua_api_nvim_load_context(lua_State *lstate)
{
  Error err = ERROR_INIT;
  if (lua_gettop(lstate) != 1) {
    api_set_error(&err, kErrorTypeValidation, "Expected 1 argument");
    goto exit_0;
  }
  if (!nlua_is_deferred_safe()) {
    return luaL_error(lstate, e_luv_api_disabled, "nvim_load_context");
  }
    const Dictionary arg1 = nlua_pop_Dictionary(lstate, false, &err);
  if (ERROR_SET(&err)) {
    goto exit_0;
  }

  const Object ret = nvim_load_context(arg1);
  nlua_push_Object(lstate, ret, true);
api_free_object(ret);

  api_free_dictionary(arg1);

exit_0:
  if (ERROR_SET(&err)) {
    luaL_where(lstate, 1);
    lua_pushstring(lstate, err.msg);
    api_clear_error(&err);
    lua_concat(lstate, 2);
    return lua_error(lstate);
  }

  return 1;
}

static int nlua_api_nvim_get_mode(lua_State *lstate)
{
  Error err = ERROR_INIT;
  if (lua_gettop(lstate) != 0) {
    api_set_error(&err, kErrorTypeValidation, "Expected 0 arguments");
    goto exit_0;
  }
  const Dictionary ret = nvim_get_mode();
  nlua_push_Dictionary(lstate, ret, true);
api_free_dictionary(ret);


exit_0:
  if (ERROR_SET(&err)) {
    luaL_where(lstate, 1);
    lua_pushstring(lstate, err.msg);
    api_clear_error(&err);
    lua_concat(lstate, 2);
    return lua_error(lstate);
  }

  return 1;
}

static int nlua_api_nvim_get_keymap(lua_State *lstate)
{
  Error err = ERROR_INIT;
  if (lua_gettop(lstate) != 1) {
    api_set_error(&err, kErrorTypeValidation, "Expected 1 argument");
    goto exit_0;
  }
  if (!nlua_is_deferred_safe()) {
    return luaL_error(lstate, e_luv_api_disabled, "nvim_get_keymap");
  }
    const String arg1 = nlua_pop_String(lstate, &err);
  if (ERROR_SET(&err)) {
    goto exit_0;
  }

  const ArrayOf(Dictionary) ret = nvim_get_keymap(arg1);
  nlua_push_Array(lstate, ret, true);
api_free_array(ret);

  api_free_string(arg1);

exit_0:
  if (ERROR_SET(&err)) {
    luaL_where(lstate, 1);
    lua_pushstring(lstate, err.msg);
    api_clear_error(&err);
    lua_concat(lstate, 2);
    return lua_error(lstate);
  }

  return 1;
}

static int nlua_api_nvim_set_keymap(lua_State *lstate)
{
  Error err = ERROR_INIT;
  if (lua_gettop(lstate) != 4) {
    api_set_error(&err, kErrorTypeValidation, "Expected 4 arguments");
    goto exit_0;
  }
  if (!nlua_is_deferred_safe()) {
    return luaL_error(lstate, e_luv_api_disabled, "nvim_set_keymap");
  }
    KeyDict_keymap arg4 = { 0 }; nlua_pop_keydict(lstate, &arg4, KeyDict_keymap_get_field, &err);
  if (ERROR_SET(&err)) {
    goto exit_1;
  }

    const String arg3 = nlua_pop_String(lstate, &err);
  if (ERROR_SET(&err)) {
    goto exit_1;
  }

    const String arg2 = nlua_pop_String(lstate, &err);
  if (ERROR_SET(&err)) {
    goto exit_2;
  }

    const String arg1 = nlua_pop_String(lstate, &err);
  if (ERROR_SET(&err)) {
    goto exit_3;
  }

  nvim_set_keymap(LUA_INTERNAL_CALL, arg1, arg2, arg3, &arg4, &err);

  api_free_string(arg1);
exit_3:
  api_free_string(arg2);
exit_2:
  api_free_string(arg3);
exit_1:
  api_free_keydict_keymap(&arg4);

exit_0:
  if (ERROR_SET(&err)) {
    luaL_where(lstate, 1);
    lua_pushstring(lstate, err.msg);
    api_clear_error(&err);
    lua_concat(lstate, 2);
    return lua_error(lstate);
  }

  return 0;
}

static int nlua_api_nvim_del_keymap(lua_State *lstate)
{
  Error err = ERROR_INIT;
  if (lua_gettop(lstate) != 2) {
    api_set_error(&err, kErrorTypeValidation, "Expected 2 arguments");
    goto exit_0;
  }
  if (!nlua_is_deferred_safe()) {
    return luaL_error(lstate, e_luv_api_disabled, "nvim_del_keymap");
  }
    const String arg2 = nlua_pop_String(lstate, &err);
  if (ERROR_SET(&err)) {
    goto exit_0;
  }

    const String arg1 = nlua_pop_String(lstate, &err);
  if (ERROR_SET(&err)) {
    goto exit_1;
  }

  nvim_del_keymap(LUA_INTERNAL_CALL, arg1, arg2, &err);

  api_free_string(arg1);
exit_1:
  api_free_string(arg2);

exit_0:
  if (ERROR_SET(&err)) {
    luaL_where(lstate, 1);
    lua_pushstring(lstate, err.msg);
    api_clear_error(&err);
    lua_concat(lstate, 2);
    return lua_error(lstate);
  }

  return 0;
}

static int nlua_api_nvim_get_chan_info(lua_State *lstate)
{
  Error err = ERROR_INIT;
  if (lua_gettop(lstate) != 1) {
    api_set_error(&err, kErrorTypeValidation, "Expected 1 argument");
    goto exit_0;
  }
  if (!nlua_is_deferred_safe()) {
    return luaL_error(lstate, e_luv_api_disabled, "nvim_get_chan_info");
  }
    const Integer arg1 = nlua_pop_Integer(lstate, &err);
  if (ERROR_SET(&err)) {
    goto exit_0;
  }

  const Dictionary ret = nvim_get_chan_info(arg1, &err);
  nlua_push_Dictionary(lstate, ret, true);
api_free_dictionary(ret);

  api_free_integer(arg1);

exit_0:
  if (ERROR_SET(&err)) {
    luaL_where(lstate, 1);
    lua_pushstring(lstate, err.msg);
    api_clear_error(&err);
    lua_concat(lstate, 2);
    return lua_error(lstate);
  }

  return 1;
}

static int nlua_api_nvim_list_chans(lua_State *lstate)
{
  Error err = ERROR_INIT;
  if (lua_gettop(lstate) != 0) {
    api_set_error(&err, kErrorTypeValidation, "Expected 0 arguments");
    goto exit_0;
  }
  if (!nlua_is_deferred_safe()) {
    return luaL_error(lstate, e_luv_api_disabled, "nvim_list_chans");
  }
  const Array ret = nvim_list_chans();
  nlua_push_Array(lstate, ret, true);
api_free_array(ret);


exit_0:
  if (ERROR_SET(&err)) {
    luaL_where(lstate, 1);
    lua_pushstring(lstate, err.msg);
    api_clear_error(&err);
    lua_concat(lstate, 2);
    return lua_error(lstate);
  }

  return 1;
}

static int nlua_api_nvim__id(lua_State *lstate)
{
  Error err = ERROR_INIT;
  if (lua_gettop(lstate) != 1) {
    api_set_error(&err, kErrorTypeValidation, "Expected 1 argument");
    goto exit_0;
  }
  if (!nlua_is_deferred_safe()) {
    return luaL_error(lstate, e_luv_api_disabled, "nvim__id");
  }
    const Object arg1 = nlua_pop_Object(lstate, true, &err);
  if (ERROR_SET(&err)) {
    goto exit_0;
  }

  const Object ret = nvim__id(arg1);
  nlua_push_Object(lstate, ret, true);
api_free_object(ret);

  api_free_object(arg1);

exit_0:
  if (ERROR_SET(&err)) {
    luaL_where(lstate, 1);
    lua_pushstring(lstate, err.msg);
    api_clear_error(&err);
    lua_concat(lstate, 2);
    return lua_error(lstate);
  }

  return 1;
}

static int nlua_api_nvim__id_array(lua_State *lstate)
{
  Error err = ERROR_INIT;
  if (lua_gettop(lstate) != 1) {
    api_set_error(&err, kErrorTypeValidation, "Expected 1 argument");
    goto exit_0;
  }
  if (!nlua_is_deferred_safe()) {
    return luaL_error(lstate, e_luv_api_disabled, "nvim__id_array");
  }
    const Array arg1 = nlua_pop_Array(lstate, &err);
  if (ERROR_SET(&err)) {
    goto exit_0;
  }

  const Array ret = nvim__id_array(arg1);
  nlua_push_Array(lstate, ret, true);
api_free_array(ret);

  api_free_array(arg1);

exit_0:
  if (ERROR_SET(&err)) {
    luaL_where(lstate, 1);
    lua_pushstring(lstate, err.msg);
    api_clear_error(&err);
    lua_concat(lstate, 2);
    return lua_error(lstate);
  }

  return 1;
}

static int nlua_api_nvim__id_dictionary(lua_State *lstate)
{
  Error err = ERROR_INIT;
  if (lua_gettop(lstate) != 1) {
    api_set_error(&err, kErrorTypeValidation, "Expected 1 argument");
    goto exit_0;
  }
  if (!nlua_is_deferred_safe()) {
    return luaL_error(lstate, e_luv_api_disabled, "nvim__id_dictionary");
  }
    const Dictionary arg1 = nlua_pop_Dictionary(lstate, false, &err);
  if (ERROR_SET(&err)) {
    goto exit_0;
  }

  const Dictionary ret = nvim__id_dictionary(arg1);
  nlua_push_Dictionary(lstate, ret, true);
api_free_dictionary(ret);

  api_free_dictionary(arg1);

exit_0:
  if (ERROR_SET(&err)) {
    luaL_where(lstate, 1);
    lua_pushstring(lstate, err.msg);
    api_clear_error(&err);
    lua_concat(lstate, 2);
    return lua_error(lstate);
  }

  return 1;
}

static int nlua_api_nvim__id_float(lua_State *lstate)
{
  Error err = ERROR_INIT;
  if (lua_gettop(lstate) != 1) {
    api_set_error(&err, kErrorTypeValidation, "Expected 1 argument");
    goto exit_0;
  }
  if (!nlua_is_deferred_safe()) {
    return luaL_error(lstate, e_luv_api_disabled, "nvim__id_float");
  }
    const Float arg1 = nlua_pop_Float(lstate, &err);
  if (ERROR_SET(&err)) {
    goto exit_0;
  }

  const Float ret = nvim__id_float(arg1);
  nlua_push_Float(lstate, ret, true);
api_free_float(ret);

  api_free_float(arg1);

exit_0:
  if (ERROR_SET(&err)) {
    luaL_where(lstate, 1);
    lua_pushstring(lstate, err.msg);
    api_clear_error(&err);
    lua_concat(lstate, 2);
    return lua_error(lstate);
  }

  return 1;
}

static int nlua_api_nvim__stats(lua_State *lstate)
{
  Error err = ERROR_INIT;
  if (lua_gettop(lstate) != 0) {
    api_set_error(&err, kErrorTypeValidation, "Expected 0 arguments");
    goto exit_0;
  }
  if (!nlua_is_deferred_safe()) {
    return luaL_error(lstate, e_luv_api_disabled, "nvim__stats");
  }
  const Dictionary ret = nvim__stats();
  nlua_push_Dictionary(lstate, ret, true);
api_free_dictionary(ret);


exit_0:
  if (ERROR_SET(&err)) {
    luaL_where(lstate, 1);
    lua_pushstring(lstate, err.msg);
    api_clear_error(&err);
    lua_concat(lstate, 2);
    return lua_error(lstate);
  }

  return 1;
}

static int nlua_api_nvim_list_uis(lua_State *lstate)
{
  Error err = ERROR_INIT;
  if (lua_gettop(lstate) != 0) {
    api_set_error(&err, kErrorTypeValidation, "Expected 0 arguments");
    goto exit_0;
  }
  if (!nlua_is_deferred_safe()) {
    return luaL_error(lstate, e_luv_api_disabled, "nvim_list_uis");
  }
  const Array ret = nvim_list_uis();
  nlua_push_Array(lstate, ret, true);
api_free_array(ret);


exit_0:
  if (ERROR_SET(&err)) {
    luaL_where(lstate, 1);
    lua_pushstring(lstate, err.msg);
    api_clear_error(&err);
    lua_concat(lstate, 2);
    return lua_error(lstate);
  }

  return 1;
}

static int nlua_api_nvim_get_proc_children(lua_State *lstate)
{
  Error err = ERROR_INIT;
  if (lua_gettop(lstate) != 1) {
    api_set_error(&err, kErrorTypeValidation, "Expected 1 argument");
    goto exit_0;
  }
  if (!nlua_is_deferred_safe()) {
    return luaL_error(lstate, e_luv_api_disabled, "nvim_get_proc_children");
  }
    const Integer arg1 = nlua_pop_Integer(lstate, &err);
  if (ERROR_SET(&err)) {
    goto exit_0;
  }

  const Array ret = nvim_get_proc_children(arg1, &err);
  nlua_push_Array(lstate, ret, true);
api_free_array(ret);

  api_free_integer(arg1);

exit_0:
  if (ERROR_SET(&err)) {
    luaL_where(lstate, 1);
    lua_pushstring(lstate, err.msg);
    api_clear_error(&err);
    lua_concat(lstate, 2);
    return lua_error(lstate);
  }

  return 1;
}

static int nlua_api_nvim_get_proc(lua_State *lstate)
{
  Error err = ERROR_INIT;
  if (lua_gettop(lstate) != 1) {
    api_set_error(&err, kErrorTypeValidation, "Expected 1 argument");
    goto exit_0;
  }
  if (!nlua_is_deferred_safe()) {
    return luaL_error(lstate, e_luv_api_disabled, "nvim_get_proc");
  }
    const Integer arg1 = nlua_pop_Integer(lstate, &err);
  if (ERROR_SET(&err)) {
    goto exit_0;
  }

  const Object ret = nvim_get_proc(arg1, &err);
  nlua_push_Object(lstate, ret, true);
api_free_object(ret);

  api_free_integer(arg1);

exit_0:
  if (ERROR_SET(&err)) {
    luaL_where(lstate, 1);
    lua_pushstring(lstate, err.msg);
    api_clear_error(&err);
    lua_concat(lstate, 2);
    return lua_error(lstate);
  }

  return 1;
}

static int nlua_api_nvim_select_popupmenu_item(lua_State *lstate)
{
  Error err = ERROR_INIT;
  if (lua_gettop(lstate) != 4) {
    api_set_error(&err, kErrorTypeValidation, "Expected 4 arguments");
    goto exit_0;
  }
  if (!nlua_is_deferred_safe()) {
    return luaL_error(lstate, e_luv_api_disabled, "nvim_select_popupmenu_item");
  }
    const Dictionary arg4 = nlua_pop_Dictionary(lstate, false, &err);
  if (ERROR_SET(&err)) {
    goto exit_0;
  }

    const Boolean arg3 = nlua_pop_Boolean(lstate, &err);
  if (ERROR_SET(&err)) {
    goto exit_1;
  }

    const Boolean arg2 = nlua_pop_Boolean(lstate, &err);
  if (ERROR_SET(&err)) {
    goto exit_2;
  }

    const Integer arg1 = nlua_pop_Integer(lstate, &err);
  if (ERROR_SET(&err)) {
    goto exit_3;
  }

  nvim_select_popupmenu_item(arg1, arg2, arg3, arg4, &err);

  api_free_integer(arg1);
exit_3:
  api_free_boolean(arg2);
exit_2:
  api_free_boolean(arg3);
exit_1:
  api_free_dictionary(arg4);

exit_0:
  if (ERROR_SET(&err)) {
    luaL_where(lstate, 1);
    lua_pushstring(lstate, err.msg);
    api_clear_error(&err);
    lua_concat(lstate, 2);
    return lua_error(lstate);
  }

  return 0;
}

static int nlua_api_nvim__inspect_cell(lua_State *lstate)
{
  Error err = ERROR_INIT;
  if (lua_gettop(lstate) != 3) {
    api_set_error(&err, kErrorTypeValidation, "Expected 3 arguments");
    goto exit_0;
  }
  if (!nlua_is_deferred_safe()) {
    return luaL_error(lstate, e_luv_api_disabled, "nvim__inspect_cell");
  }
    const Integer arg3 = nlua_pop_Integer(lstate, &err);
  if (ERROR_SET(&err)) {
    goto exit_0;
  }

    const Integer arg2 = nlua_pop_Integer(lstate, &err);
  if (ERROR_SET(&err)) {
    goto exit_1;
  }

    const Integer arg1 = nlua_pop_Integer(lstate, &err);
  if (ERROR_SET(&err)) {
    goto exit_2;
  }

  Arena arena = ARENA_EMPTY;
  const Array ret = nvim__inspect_cell(arg1, arg2, arg3, &arena, &err);
  nlua_push_Array(lstate, ret, true);
arena_mem_free(arena_finish(&arena));

  api_free_integer(arg1);
exit_2:
  api_free_integer(arg2);
exit_1:
  api_free_integer(arg3);

exit_0:
  if (ERROR_SET(&err)) {
    luaL_where(lstate, 1);
    lua_pushstring(lstate, err.msg);
    api_clear_error(&err);
    lua_concat(lstate, 2);
    return lua_error(lstate);
  }

  return 1;
}

static int nlua_api_nvim__screenshot(lua_State *lstate)
{
  Error err = ERROR_INIT;
  if (lua_gettop(lstate) != 1) {
    api_set_error(&err, kErrorTypeValidation, "Expected 1 argument");
    goto exit_0;
  }
    const String arg1 = nlua_pop_String(lstate, &err);
  if (ERROR_SET(&err)) {
    goto exit_0;
  }

  nvim__screenshot(arg1);

  api_free_string(arg1);

exit_0:
  if (ERROR_SET(&err)) {
    luaL_where(lstate, 1);
    lua_pushstring(lstate, err.msg);
    api_clear_error(&err);
    lua_concat(lstate, 2);
    return lua_error(lstate);
  }

  return 0;
}

static int nlua_api_nvim__unpack(lua_State *lstate)
{
  Error err = ERROR_INIT;
  if (lua_gettop(lstate) != 1) {
    api_set_error(&err, kErrorTypeValidation, "Expected 1 argument");
    goto exit_0;
  }
    const String arg1 = nlua_pop_String(lstate, &err);
  if (ERROR_SET(&err)) {
    goto exit_0;
  }

  const Object ret = nvim__unpack(arg1, &err);
  nlua_push_Object(lstate, ret, true);
api_free_object(ret);

  api_free_string(arg1);

exit_0:
  if (ERROR_SET(&err)) {
    luaL_where(lstate, 1);
    lua_pushstring(lstate, err.msg);
    api_clear_error(&err);
    lua_concat(lstate, 2);
    return lua_error(lstate);
  }

  return 1;
}

static int nlua_api_nvim_del_mark(lua_State *lstate)
{
  Error err = ERROR_INIT;
  if (lua_gettop(lstate) != 1) {
    api_set_error(&err, kErrorTypeValidation, "Expected 1 argument");
    goto exit_0;
  }
  if (!nlua_is_deferred_safe()) {
    return luaL_error(lstate, e_luv_api_disabled, "nvim_del_mark");
  }
    const String arg1 = nlua_pop_String(lstate, &err);
  if (ERROR_SET(&err)) {
    goto exit_0;
  }

  const Boolean ret = nvim_del_mark(arg1, &err);
  nlua_push_Boolean(lstate, ret, true);
api_free_boolean(ret);

  api_free_string(arg1);

exit_0:
  if (ERROR_SET(&err)) {
    luaL_where(lstate, 1);
    lua_pushstring(lstate, err.msg);
    api_clear_error(&err);
    lua_concat(lstate, 2);
    return lua_error(lstate);
  }

  return 1;
}

static int nlua_api_nvim_get_mark(lua_State *lstate)
{
  Error err = ERROR_INIT;
  if (lua_gettop(lstate) != 2) {
    api_set_error(&err, kErrorTypeValidation, "Expected 2 arguments");
    goto exit_0;
  }
  if (!nlua_is_deferred_safe()) {
    return luaL_error(lstate, e_luv_api_disabled, "nvim_get_mark");
  }
    const Dictionary arg2 = nlua_pop_Dictionary(lstate, false, &err);
  if (ERROR_SET(&err)) {
    goto exit_0;
  }

    const String arg1 = nlua_pop_String(lstate, &err);
  if (ERROR_SET(&err)) {
    goto exit_1;
  }

  const Array ret = nvim_get_mark(arg1, arg2, &err);
  nlua_push_Array(lstate, ret, true);
api_free_array(ret);

  api_free_string(arg1);
exit_1:
  api_free_dictionary(arg2);

exit_0:
  if (ERROR_SET(&err)) {
    luaL_where(lstate, 1);
    lua_pushstring(lstate, err.msg);
    api_clear_error(&err);
    lua_concat(lstate, 2);
    return lua_error(lstate);
  }

  return 1;
}

static int nlua_api_nvim_eval_statusline(lua_State *lstate)
{
  Error err = ERROR_INIT;
  if (lua_gettop(lstate) != 2) {
    api_set_error(&err, kErrorTypeValidation, "Expected 2 arguments");
    goto exit_0;
  }
    KeyDict_eval_statusline arg2 = { 0 }; nlua_pop_keydict(lstate, &arg2, KeyDict_eval_statusline_get_field, &err);
  if (ERROR_SET(&err)) {
    goto exit_1;
  }

    const String arg1 = nlua_pop_String(lstate, &err);
  if (ERROR_SET(&err)) {
    goto exit_1;
  }

  const Dictionary ret = nvim_eval_statusline(arg1, &arg2, &err);
  nlua_push_Dictionary(lstate, ret, true);
api_free_dictionary(ret);

  api_free_string(arg1);
exit_1:
  api_free_keydict_eval_statusline(&arg2);

exit_0:
  if (ERROR_SET(&err)) {
    luaL_where(lstate, 1);
    lua_pushstring(lstate, err.msg);
    api_clear_error(&err);
    lua_concat(lstate, 2);
    return lua_error(lstate);
  }

  return 1;
}

static int nlua_api_nvim_exec(lua_State *lstate)
{
  Error err = ERROR_INIT;
  if (lua_gettop(lstate) != 2) {
    api_set_error(&err, kErrorTypeValidation, "Expected 2 arguments");
    goto exit_0;
  }
  if (!nlua_is_deferred_safe()) {
    return luaL_error(lstate, e_luv_api_disabled, "nvim_exec");
  }
    const Boolean arg2 = nlua_pop_Boolean(lstate, &err);
  if (ERROR_SET(&err)) {
    goto exit_0;
  }

    const String arg1 = nlua_pop_String(lstate, &err);
  if (ERROR_SET(&err)) {
    goto exit_1;
  }

  const String ret = nvim_exec(LUA_INTERNAL_CALL, arg1, arg2, &err);
  nlua_push_String(lstate, ret, true);
api_free_string(ret);

  api_free_string(arg1);
exit_1:
  api_free_boolean(arg2);

exit_0:
  if (ERROR_SET(&err)) {
    luaL_where(lstate, 1);
    lua_pushstring(lstate, err.msg);
    api_clear_error(&err);
    lua_concat(lstate, 2);
    return lua_error(lstate);
  }

  return 1;
}

static int nlua_api_nvim_command(lua_State *lstate)
{
  Error err = ERROR_INIT;
  if (lua_gettop(lstate) != 1) {
    api_set_error(&err, kErrorTypeValidation, "Expected 1 argument");
    goto exit_0;
  }
  if (!nlua_is_deferred_safe()) {
    return luaL_error(lstate, e_luv_api_disabled, "nvim_command");
  }
    const String arg1 = nlua_pop_String(lstate, &err);
  if (ERROR_SET(&err)) {
    goto exit_0;
  }

  nvim_command(arg1, &err);

  api_free_string(arg1);

exit_0:
  if (ERROR_SET(&err)) {
    luaL_where(lstate, 1);
    lua_pushstring(lstate, err.msg);
    api_clear_error(&err);
    lua_concat(lstate, 2);
    return lua_error(lstate);
  }

  return 0;
}

static int nlua_api_nvim_eval(lua_State *lstate)
{
  Error err = ERROR_INIT;
  if (lua_gettop(lstate) != 1) {
    api_set_error(&err, kErrorTypeValidation, "Expected 1 argument");
    goto exit_0;
  }
  if (!nlua_is_deferred_safe()) {
    return luaL_error(lstate, e_luv_api_disabled, "nvim_eval");
  }
    const String arg1 = nlua_pop_String(lstate, &err);
  if (ERROR_SET(&err)) {
    goto exit_0;
  }

  const Object ret = nvim_eval(arg1, &err);
  nlua_push_Object(lstate, ret, true);
api_free_object(ret);

  api_free_string(arg1);

exit_0:
  if (ERROR_SET(&err)) {
    luaL_where(lstate, 1);
    lua_pushstring(lstate, err.msg);
    api_clear_error(&err);
    lua_concat(lstate, 2);
    return lua_error(lstate);
  }

  return 1;
}

static int nlua_api_nvim_call_function(lua_State *lstate)
{
  Error err = ERROR_INIT;
  if (lua_gettop(lstate) != 2) {
    api_set_error(&err, kErrorTypeValidation, "Expected 2 arguments");
    goto exit_0;
  }
  if (!nlua_is_deferred_safe()) {
    return luaL_error(lstate, e_luv_api_disabled, "nvim_call_function");
  }
    const Array arg2 = nlua_pop_Array(lstate, &err);
  if (ERROR_SET(&err)) {
    goto exit_0;
  }

    const String arg1 = nlua_pop_String(lstate, &err);
  if (ERROR_SET(&err)) {
    goto exit_1;
  }

  const Object ret = nvim_call_function(arg1, arg2, &err);
  nlua_push_Object(lstate, ret, true);
api_free_object(ret);

  api_free_string(arg1);
exit_1:
  api_free_array(arg2);

exit_0:
  if (ERROR_SET(&err)) {
    luaL_where(lstate, 1);
    lua_pushstring(lstate, err.msg);
    api_clear_error(&err);
    lua_concat(lstate, 2);
    return lua_error(lstate);
  }

  return 1;
}

static int nlua_api_nvim_call_dict_function(lua_State *lstate)
{
  Error err = ERROR_INIT;
  if (lua_gettop(lstate) != 3) {
    api_set_error(&err, kErrorTypeValidation, "Expected 3 arguments");
    goto exit_0;
  }
  if (!nlua_is_deferred_safe()) {
    return luaL_error(lstate, e_luv_api_disabled, "nvim_call_dict_function");
  }
    const Array arg3 = nlua_pop_Array(lstate, &err);
  if (ERROR_SET(&err)) {
    goto exit_0;
  }

    const String arg2 = nlua_pop_String(lstate, &err);
  if (ERROR_SET(&err)) {
    goto exit_1;
  }

    const Object arg1 = nlua_pop_Object(lstate, true, &err);
  if (ERROR_SET(&err)) {
    goto exit_2;
  }

  const Object ret = nvim_call_dict_function(arg1, arg2, arg3, &err);
  nlua_push_Object(lstate, ret, true);
api_free_object(ret);

  api_free_object(arg1);
exit_2:
  api_free_string(arg2);
exit_1:
  api_free_array(arg3);

exit_0:
  if (ERROR_SET(&err)) {
    luaL_where(lstate, 1);
    lua_pushstring(lstate, err.msg);
    api_clear_error(&err);
    lua_concat(lstate, 2);
    return lua_error(lstate);
  }

  return 1;
}

static int nlua_api_nvim_parse_expression(lua_State *lstate)
{
  Error err = ERROR_INIT;
  if (lua_gettop(lstate) != 3) {
    api_set_error(&err, kErrorTypeValidation, "Expected 3 arguments");
    goto exit_0;
  }
    const Boolean arg3 = nlua_pop_Boolean(lstate, &err);
  if (ERROR_SET(&err)) {
    goto exit_0;
  }

    const String arg2 = nlua_pop_String(lstate, &err);
  if (ERROR_SET(&err)) {
    goto exit_1;
  }

    const String arg1 = nlua_pop_String(lstate, &err);
  if (ERROR_SET(&err)) {
    goto exit_2;
  }

  const Dictionary ret = nvim_parse_expression(arg1, arg2, arg3, &err);
  nlua_push_Dictionary(lstate, ret, true);
api_free_dictionary(ret);

  api_free_string(arg1);
exit_2:
  api_free_string(arg2);
exit_1:
  api_free_boolean(arg3);

exit_0:
  if (ERROR_SET(&err)) {
    luaL_where(lstate, 1);
    lua_pushstring(lstate, err.msg);
    api_clear_error(&err);
    lua_concat(lstate, 2);
    return lua_error(lstate);
  }

  return 1;
}

static int nlua_api_nvim_open_win(lua_State *lstate)
{
  Error err = ERROR_INIT;
  if (lua_gettop(lstate) != 3) {
    api_set_error(&err, kErrorTypeValidation, "Expected 3 arguments");
    goto exit_0;
  }
  if (!nlua_is_deferred_safe()) {
    return luaL_error(lstate, e_luv_api_disabled, "nvim_open_win");
  }
  if (textlock != 0) {
    api_set_error(&err, kErrorTypeException, "%s", e_textlock);
    goto exit_0;
  }
    KeyDict_float_config arg3 = { 0 }; nlua_pop_keydict(lstate, &arg3, KeyDict_float_config_get_field, &err);
  if (ERROR_SET(&err)) {
    goto exit_1;
  }

    const Boolean arg2 = nlua_pop_Boolean(lstate, &err);
  if (ERROR_SET(&err)) {
    goto exit_1;
  }

    const Buffer arg1 = nlua_pop_Buffer(lstate, &err);
  if (ERROR_SET(&err)) {
    goto exit_2;
  }

  const Window ret = nvim_open_win(arg1, arg2, &arg3, &err);
  nlua_push_Window(lstate, ret, true);
api_free_window(ret);

  api_free_buffer(arg1);
exit_2:
  api_free_boolean(arg2);
exit_1:
  api_free_keydict_float_config(&arg3);

exit_0:
  if (ERROR_SET(&err)) {
    luaL_where(lstate, 1);
    lua_pushstring(lstate, err.msg);
    api_clear_error(&err);
    lua_concat(lstate, 2);
    return lua_error(lstate);
  }

  return 1;
}

static int nlua_api_nvim_win_set_config(lua_State *lstate)
{
  Error err = ERROR_INIT;
  if (lua_gettop(lstate) != 2) {
    api_set_error(&err, kErrorTypeValidation, "Expected 2 arguments");
    goto exit_0;
  }
  if (!nlua_is_deferred_safe()) {
    return luaL_error(lstate, e_luv_api_disabled, "nvim_win_set_config");
  }
    KeyDict_float_config arg2 = { 0 }; nlua_pop_keydict(lstate, &arg2, KeyDict_float_config_get_field, &err);
  if (ERROR_SET(&err)) {
    goto exit_1;
  }

    const Window arg1 = nlua_pop_Window(lstate, &err);
  if (ERROR_SET(&err)) {
    goto exit_1;
  }

  nvim_win_set_config(arg1, &arg2, &err);

  api_free_window(arg1);
exit_1:
  api_free_keydict_float_config(&arg2);

exit_0:
  if (ERROR_SET(&err)) {
    luaL_where(lstate, 1);
    lua_pushstring(lstate, err.msg);
    api_clear_error(&err);
    lua_concat(lstate, 2);
    return lua_error(lstate);
  }

  return 0;
}

static int nlua_api_nvim_win_get_config(lua_State *lstate)
{
  Error err = ERROR_INIT;
  if (lua_gettop(lstate) != 1) {
    api_set_error(&err, kErrorTypeValidation, "Expected 1 argument");
    goto exit_0;
  }
  if (!nlua_is_deferred_safe()) {
    return luaL_error(lstate, e_luv_api_disabled, "nvim_win_get_config");
  }
    const Window arg1 = nlua_pop_Window(lstate, &err);
  if (ERROR_SET(&err)) {
    goto exit_0;
  }

  const Dictionary ret = nvim_win_get_config(arg1, &err);
  nlua_push_Dictionary(lstate, ret, true);
api_free_dictionary(ret);

  api_free_window(arg1);

exit_0:
  if (ERROR_SET(&err)) {
    luaL_where(lstate, 1);
    lua_pushstring(lstate, err.msg);
    api_clear_error(&err);
    lua_concat(lstate, 2);
    return lua_error(lstate);
  }

  return 1;
}

static int nlua_api_nvim_win_get_buf(lua_State *lstate)
{
  Error err = ERROR_INIT;
  if (lua_gettop(lstate) != 1) {
    api_set_error(&err, kErrorTypeValidation, "Expected 1 argument");
    goto exit_0;
  }
  if (!nlua_is_deferred_safe()) {
    return luaL_error(lstate, e_luv_api_disabled, "nvim_win_get_buf");
  }
    const Window arg1 = nlua_pop_Window(lstate, &err);
  if (ERROR_SET(&err)) {
    goto exit_0;
  }

  const Buffer ret = nvim_win_get_buf(arg1, &err);
  nlua_push_Buffer(lstate, ret, true);
api_free_buffer(ret);

  api_free_window(arg1);

exit_0:
  if (ERROR_SET(&err)) {
    luaL_where(lstate, 1);
    lua_pushstring(lstate, err.msg);
    api_clear_error(&err);
    lua_concat(lstate, 2);
    return lua_error(lstate);
  }

  return 1;
}

static int nlua_api_nvim_win_set_buf(lua_State *lstate)
{
  Error err = ERROR_INIT;
  if (lua_gettop(lstate) != 2) {
    api_set_error(&err, kErrorTypeValidation, "Expected 2 arguments");
    goto exit_0;
  }
  if (!nlua_is_deferred_safe()) {
    return luaL_error(lstate, e_luv_api_disabled, "nvim_win_set_buf");
  }
  if (textlock != 0) {
    api_set_error(&err, kErrorTypeException, "%s", e_textlock);
    goto exit_0;
  }
    const Buffer arg2 = nlua_pop_Buffer(lstate, &err);
  if (ERROR_SET(&err)) {
    goto exit_0;
  }

    const Window arg1 = nlua_pop_Window(lstate, &err);
  if (ERROR_SET(&err)) {
    goto exit_1;
  }

  nvim_win_set_buf(arg1, arg2, &err);

  api_free_window(arg1);
exit_1:
  api_free_buffer(arg2);

exit_0:
  if (ERROR_SET(&err)) {
    luaL_where(lstate, 1);
    lua_pushstring(lstate, err.msg);
    api_clear_error(&err);
    lua_concat(lstate, 2);
    return lua_error(lstate);
  }

  return 0;
}

static int nlua_api_nvim_win_get_cursor(lua_State *lstate)
{
  Error err = ERROR_INIT;
  if (lua_gettop(lstate) != 1) {
    api_set_error(&err, kErrorTypeValidation, "Expected 1 argument");
    goto exit_0;
  }
  if (!nlua_is_deferred_safe()) {
    return luaL_error(lstate, e_luv_api_disabled, "nvim_win_get_cursor");
  }
    const Window arg1 = nlua_pop_Window(lstate, &err);
  if (ERROR_SET(&err)) {
    goto exit_0;
  }

  const ArrayOf(Integer, 2) ret = nvim_win_get_cursor(arg1, &err);
  nlua_push_Array(lstate, ret, true);
api_free_array(ret);

  api_free_window(arg1);

exit_0:
  if (ERROR_SET(&err)) {
    luaL_where(lstate, 1);
    lua_pushstring(lstate, err.msg);
    api_clear_error(&err);
    lua_concat(lstate, 2);
    return lua_error(lstate);
  }

  return 1;
}

static int nlua_api_nvim_win_set_cursor(lua_State *lstate)
{
  Error err = ERROR_INIT;
  if (lua_gettop(lstate) != 2) {
    api_set_error(&err, kErrorTypeValidation, "Expected 2 arguments");
    goto exit_0;
  }
  if (!nlua_is_deferred_safe()) {
    return luaL_error(lstate, e_luv_api_disabled, "nvim_win_set_cursor");
  }
    const ArrayOf(Integer, 2) arg2 = nlua_pop_Array(lstate, &err);
  if (ERROR_SET(&err)) {
    goto exit_0;
  }

    const Window arg1 = nlua_pop_Window(lstate, &err);
  if (ERROR_SET(&err)) {
    goto exit_1;
  }

  nvim_win_set_cursor(arg1, arg2, &err);

  api_free_window(arg1);
exit_1:
  api_free_array(arg2);

exit_0:
  if (ERROR_SET(&err)) {
    luaL_where(lstate, 1);
    lua_pushstring(lstate, err.msg);
    api_clear_error(&err);
    lua_concat(lstate, 2);
    return lua_error(lstate);
  }

  return 0;
}

static int nlua_api_nvim_win_get_height(lua_State *lstate)
{
  Error err = ERROR_INIT;
  if (lua_gettop(lstate) != 1) {
    api_set_error(&err, kErrorTypeValidation, "Expected 1 argument");
    goto exit_0;
  }
  if (!nlua_is_deferred_safe()) {
    return luaL_error(lstate, e_luv_api_disabled, "nvim_win_get_height");
  }
    const Window arg1 = nlua_pop_Window(lstate, &err);
  if (ERROR_SET(&err)) {
    goto exit_0;
  }

  const Integer ret = nvim_win_get_height(arg1, &err);
  nlua_push_Integer(lstate, ret, true);
api_free_integer(ret);

  api_free_window(arg1);

exit_0:
  if (ERROR_SET(&err)) {
    luaL_where(lstate, 1);
    lua_pushstring(lstate, err.msg);
    api_clear_error(&err);
    lua_concat(lstate, 2);
    return lua_error(lstate);
  }

  return 1;
}

static int nlua_api_nvim_win_set_height(lua_State *lstate)
{
  Error err = ERROR_INIT;
  if (lua_gettop(lstate) != 2) {
    api_set_error(&err, kErrorTypeValidation, "Expected 2 arguments");
    goto exit_0;
  }
  if (!nlua_is_deferred_safe()) {
    return luaL_error(lstate, e_luv_api_disabled, "nvim_win_set_height");
  }
    const Integer arg2 = nlua_pop_Integer(lstate, &err);
  if (ERROR_SET(&err)) {
    goto exit_0;
  }

    const Window arg1 = nlua_pop_Window(lstate, &err);
  if (ERROR_SET(&err)) {
    goto exit_1;
  }

  nvim_win_set_height(arg1, arg2, &err);

  api_free_window(arg1);
exit_1:
  api_free_integer(arg2);

exit_0:
  if (ERROR_SET(&err)) {
    luaL_where(lstate, 1);
    lua_pushstring(lstate, err.msg);
    api_clear_error(&err);
    lua_concat(lstate, 2);
    return lua_error(lstate);
  }

  return 0;
}

static int nlua_api_nvim_win_get_width(lua_State *lstate)
{
  Error err = ERROR_INIT;
  if (lua_gettop(lstate) != 1) {
    api_set_error(&err, kErrorTypeValidation, "Expected 1 argument");
    goto exit_0;
  }
  if (!nlua_is_deferred_safe()) {
    return luaL_error(lstate, e_luv_api_disabled, "nvim_win_get_width");
  }
    const Window arg1 = nlua_pop_Window(lstate, &err);
  if (ERROR_SET(&err)) {
    goto exit_0;
  }

  const Integer ret = nvim_win_get_width(arg1, &err);
  nlua_push_Integer(lstate, ret, true);
api_free_integer(ret);

  api_free_window(arg1);

exit_0:
  if (ERROR_SET(&err)) {
    luaL_where(lstate, 1);
    lua_pushstring(lstate, err.msg);
    api_clear_error(&err);
    lua_concat(lstate, 2);
    return lua_error(lstate);
  }

  return 1;
}

static int nlua_api_nvim_win_set_width(lua_State *lstate)
{
  Error err = ERROR_INIT;
  if (lua_gettop(lstate) != 2) {
    api_set_error(&err, kErrorTypeValidation, "Expected 2 arguments");
    goto exit_0;
  }
  if (!nlua_is_deferred_safe()) {
    return luaL_error(lstate, e_luv_api_disabled, "nvim_win_set_width");
  }
    const Integer arg2 = nlua_pop_Integer(lstate, &err);
  if (ERROR_SET(&err)) {
    goto exit_0;
  }

    const Window arg1 = nlua_pop_Window(lstate, &err);
  if (ERROR_SET(&err)) {
    goto exit_1;
  }

  nvim_win_set_width(arg1, arg2, &err);

  api_free_window(arg1);
exit_1:
  api_free_integer(arg2);

exit_0:
  if (ERROR_SET(&err)) {
    luaL_where(lstate, 1);
    lua_pushstring(lstate, err.msg);
    api_clear_error(&err);
    lua_concat(lstate, 2);
    return lua_error(lstate);
  }

  return 0;
}

static int nlua_api_nvim_win_get_var(lua_State *lstate)
{
  Error err = ERROR_INIT;
  if (lua_gettop(lstate) != 2) {
    api_set_error(&err, kErrorTypeValidation, "Expected 2 arguments");
    goto exit_0;
  }
  if (!nlua_is_deferred_safe()) {
    return luaL_error(lstate, e_luv_api_disabled, "nvim_win_get_var");
  }
    const String arg2 = nlua_pop_String(lstate, &err);
  if (ERROR_SET(&err)) {
    goto exit_0;
  }

    const Window arg1 = nlua_pop_Window(lstate, &err);
  if (ERROR_SET(&err)) {
    goto exit_1;
  }

  const Object ret = nvim_win_get_var(arg1, arg2, &err);
  nlua_push_Object(lstate, ret, true);
api_free_object(ret);

  api_free_window(arg1);
exit_1:
  api_free_string(arg2);

exit_0:
  if (ERROR_SET(&err)) {
    luaL_where(lstate, 1);
    lua_pushstring(lstate, err.msg);
    api_clear_error(&err);
    lua_concat(lstate, 2);
    return lua_error(lstate);
  }

  return 1;
}

static int nlua_api_nvim_win_set_var(lua_State *lstate)
{
  Error err = ERROR_INIT;
  if (lua_gettop(lstate) != 3) {
    api_set_error(&err, kErrorTypeValidation, "Expected 3 arguments");
    goto exit_0;
  }
  if (!nlua_is_deferred_safe()) {
    return luaL_error(lstate, e_luv_api_disabled, "nvim_win_set_var");
  }
    const Object arg3 = nlua_pop_Object(lstate, true, &err);
  if (ERROR_SET(&err)) {
    goto exit_0;
  }

    const String arg2 = nlua_pop_String(lstate, &err);
  if (ERROR_SET(&err)) {
    goto exit_1;
  }

    const Window arg1 = nlua_pop_Window(lstate, &err);
  if (ERROR_SET(&err)) {
    goto exit_2;
  }

  nvim_win_set_var(arg1, arg2, arg3, &err);

  api_free_window(arg1);
exit_2:
  api_free_string(arg2);
exit_1:
  api_free_object(arg3);

exit_0:
  if (ERROR_SET(&err)) {
    luaL_where(lstate, 1);
    lua_pushstring(lstate, err.msg);
    api_clear_error(&err);
    lua_concat(lstate, 2);
    return lua_error(lstate);
  }

  return 0;
}

static int nlua_api_nvim_win_del_var(lua_State *lstate)
{
  Error err = ERROR_INIT;
  if (lua_gettop(lstate) != 2) {
    api_set_error(&err, kErrorTypeValidation, "Expected 2 arguments");
    goto exit_0;
  }
  if (!nlua_is_deferred_safe()) {
    return luaL_error(lstate, e_luv_api_disabled, "nvim_win_del_var");
  }
    const String arg2 = nlua_pop_String(lstate, &err);
  if (ERROR_SET(&err)) {
    goto exit_0;
  }

    const Window arg1 = nlua_pop_Window(lstate, &err);
  if (ERROR_SET(&err)) {
    goto exit_1;
  }

  nvim_win_del_var(arg1, arg2, &err);

  api_free_window(arg1);
exit_1:
  api_free_string(arg2);

exit_0:
  if (ERROR_SET(&err)) {
    luaL_where(lstate, 1);
    lua_pushstring(lstate, err.msg);
    api_clear_error(&err);
    lua_concat(lstate, 2);
    return lua_error(lstate);
  }

  return 0;
}

static int nlua_api_nvim_win_get_position(lua_State *lstate)
{
  Error err = ERROR_INIT;
  if (lua_gettop(lstate) != 1) {
    api_set_error(&err, kErrorTypeValidation, "Expected 1 argument");
    goto exit_0;
  }
  if (!nlua_is_deferred_safe()) {
    return luaL_error(lstate, e_luv_api_disabled, "nvim_win_get_position");
  }
    const Window arg1 = nlua_pop_Window(lstate, &err);
  if (ERROR_SET(&err)) {
    goto exit_0;
  }

  const ArrayOf(Integer, 2) ret = nvim_win_get_position(arg1, &err);
  nlua_push_Array(lstate, ret, true);
api_free_array(ret);

  api_free_window(arg1);

exit_0:
  if (ERROR_SET(&err)) {
    luaL_where(lstate, 1);
    lua_pushstring(lstate, err.msg);
    api_clear_error(&err);
    lua_concat(lstate, 2);
    return lua_error(lstate);
  }

  return 1;
}

static int nlua_api_nvim_win_get_tabpage(lua_State *lstate)
{
  Error err = ERROR_INIT;
  if (lua_gettop(lstate) != 1) {
    api_set_error(&err, kErrorTypeValidation, "Expected 1 argument");
    goto exit_0;
  }
  if (!nlua_is_deferred_safe()) {
    return luaL_error(lstate, e_luv_api_disabled, "nvim_win_get_tabpage");
  }
    const Window arg1 = nlua_pop_Window(lstate, &err);
  if (ERROR_SET(&err)) {
    goto exit_0;
  }

  const Tabpage ret = nvim_win_get_tabpage(arg1, &err);
  nlua_push_Tabpage(lstate, ret, true);
api_free_tabpage(ret);

  api_free_window(arg1);

exit_0:
  if (ERROR_SET(&err)) {
    luaL_where(lstate, 1);
    lua_pushstring(lstate, err.msg);
    api_clear_error(&err);
    lua_concat(lstate, 2);
    return lua_error(lstate);
  }

  return 1;
}

static int nlua_api_nvim_win_get_number(lua_State *lstate)
{
  Error err = ERROR_INIT;
  if (lua_gettop(lstate) != 1) {
    api_set_error(&err, kErrorTypeValidation, "Expected 1 argument");
    goto exit_0;
  }
  if (!nlua_is_deferred_safe()) {
    return luaL_error(lstate, e_luv_api_disabled, "nvim_win_get_number");
  }
    const Window arg1 = nlua_pop_Window(lstate, &err);
  if (ERROR_SET(&err)) {
    goto exit_0;
  }

  const Integer ret = nvim_win_get_number(arg1, &err);
  nlua_push_Integer(lstate, ret, true);
api_free_integer(ret);

  api_free_window(arg1);

exit_0:
  if (ERROR_SET(&err)) {
    luaL_where(lstate, 1);
    lua_pushstring(lstate, err.msg);
    api_clear_error(&err);
    lua_concat(lstate, 2);
    return lua_error(lstate);
  }

  return 1;
}

static int nlua_api_nvim_win_is_valid(lua_State *lstate)
{
  Error err = ERROR_INIT;
  if (lua_gettop(lstate) != 1) {
    api_set_error(&err, kErrorTypeValidation, "Expected 1 argument");
    goto exit_0;
  }
  if (!nlua_is_deferred_safe()) {
    return luaL_error(lstate, e_luv_api_disabled, "nvim_win_is_valid");
  }
    const Window arg1 = nlua_pop_Window(lstate, &err);
  if (ERROR_SET(&err)) {
    goto exit_0;
  }

  const Boolean ret = nvim_win_is_valid(arg1);
  nlua_push_Boolean(lstate, ret, true);
api_free_boolean(ret);

  api_free_window(arg1);

exit_0:
  if (ERROR_SET(&err)) {
    luaL_where(lstate, 1);
    lua_pushstring(lstate, err.msg);
    api_clear_error(&err);
    lua_concat(lstate, 2);
    return lua_error(lstate);
  }

  return 1;
}

static int nlua_api_nvim_win_hide(lua_State *lstate)
{
  Error err = ERROR_INIT;
  if (lua_gettop(lstate) != 1) {
    api_set_error(&err, kErrorTypeValidation, "Expected 1 argument");
    goto exit_0;
  }
  if (!nlua_is_deferred_safe()) {
    return luaL_error(lstate, e_luv_api_disabled, "nvim_win_hide");
  }
  if (textlock != 0) {
    api_set_error(&err, kErrorTypeException, "%s", e_textlock);
    goto exit_0;
  }
    const Window arg1 = nlua_pop_Window(lstate, &err);
  if (ERROR_SET(&err)) {
    goto exit_0;
  }

  nvim_win_hide(arg1, &err);

  api_free_window(arg1);

exit_0:
  if (ERROR_SET(&err)) {
    luaL_where(lstate, 1);
    lua_pushstring(lstate, err.msg);
    api_clear_error(&err);
    lua_concat(lstate, 2);
    return lua_error(lstate);
  }

  return 0;
}

static int nlua_api_nvim_win_close(lua_State *lstate)
{
  Error err = ERROR_INIT;
  if (lua_gettop(lstate) != 2) {
    api_set_error(&err, kErrorTypeValidation, "Expected 2 arguments");
    goto exit_0;
  }
  if (!nlua_is_deferred_safe()) {
    return luaL_error(lstate, e_luv_api_disabled, "nvim_win_close");
  }
  if (textlock != 0) {
    api_set_error(&err, kErrorTypeException, "%s", e_textlock);
    goto exit_0;
  }
    const Boolean arg2 = nlua_pop_Boolean(lstate, &err);
  if (ERROR_SET(&err)) {
    goto exit_0;
  }

    const Window arg1 = nlua_pop_Window(lstate, &err);
  if (ERROR_SET(&err)) {
    goto exit_1;
  }

  nvim_win_close(arg1, arg2, &err);

  api_free_window(arg1);
exit_1:
  api_free_boolean(arg2);

exit_0:
  if (ERROR_SET(&err)) {
    luaL_where(lstate, 1);
    lua_pushstring(lstate, err.msg);
    api_clear_error(&err);
    lua_concat(lstate, 2);
    return lua_error(lstate);
  }

  return 0;
}

static int nlua_api_nvim_win_call(lua_State *lstate)
{
  Error err = ERROR_INIT;
  if (lua_gettop(lstate) != 2) {
    api_set_error(&err, kErrorTypeValidation, "Expected 2 arguments");
    goto exit_0;
  }
  if (!nlua_is_deferred_safe()) {
    return luaL_error(lstate, e_luv_api_disabled, "nvim_win_call");
  }
    const LuaRef arg2 = nlua_pop_LuaRef(lstate, &err);
  if (ERROR_SET(&err)) {
    goto exit_0;
  }

    const Window arg1 = nlua_pop_Window(lstate, &err);
  if (ERROR_SET(&err)) {
    goto exit_1;
  }

  const Object ret = nvim_win_call(arg1, arg2, &err);
  nlua_push_Object(lstate, ret, true);
api_free_object(ret);

  api_free_window(arg1);
exit_1:
  api_free_luaref(arg2);

exit_0:
  if (ERROR_SET(&err)) {
    luaL_where(lstate, 1);
    lua_pushstring(lstate, err.msg);
    api_clear_error(&err);
    lua_concat(lstate, 2);
    return lua_error(lstate);
  }

  return 1;
}

static int nlua_api_nvim_win_set_hl_ns(lua_State *lstate)
{
  Error err = ERROR_INIT;
  if (lua_gettop(lstate) != 2) {
    api_set_error(&err, kErrorTypeValidation, "Expected 2 arguments");
    goto exit_0;
  }
  if (!nlua_is_deferred_safe()) {
    return luaL_error(lstate, e_luv_api_disabled, "nvim_win_set_hl_ns");
  }
    const Integer arg2 = nlua_pop_Integer(lstate, &err);
  if (ERROR_SET(&err)) {
    goto exit_0;
  }

    const Window arg1 = nlua_pop_Window(lstate, &err);
  if (ERROR_SET(&err)) {
    goto exit_1;
  }

  nvim_win_set_hl_ns(arg1, arg2, &err);

  api_free_window(arg1);
exit_1:
  api_free_integer(arg2);

exit_0:
  if (ERROR_SET(&err)) {
    luaL_where(lstate, 1);
    lua_pushstring(lstate, err.msg);
    api_clear_error(&err);
    lua_concat(lstate, 2);
    return lua_error(lstate);
  }

  return 0;
}
void nlua_add_api_functions(lua_State *lstate);  // silence -Wmissing-prototypes
void nlua_add_api_functions(lua_State *lstate)
  FUNC_ATTR_NONNULL_ALL
{
  lua_createtable(lstate, 0, 169);

  lua_pushcfunction(lstate, &nlua_api_nvim_get_autocmds);
  lua_setfield(lstate, -2, "nvim_get_autocmds");
  lua_pushcfunction(lstate, &nlua_api_nvim_create_autocmd);
  lua_setfield(lstate, -2, "nvim_create_autocmd");
  lua_pushcfunction(lstate, &nlua_api_nvim_del_autocmd);
  lua_setfield(lstate, -2, "nvim_del_autocmd");
  lua_pushcfunction(lstate, &nlua_api_nvim_clear_autocmds);
  lua_setfield(lstate, -2, "nvim_clear_autocmds");
  lua_pushcfunction(lstate, &nlua_api_nvim_create_augroup);
  lua_setfield(lstate, -2, "nvim_create_augroup");
  lua_pushcfunction(lstate, &nlua_api_nvim_del_augroup_by_id);
  lua_setfield(lstate, -2, "nvim_del_augroup_by_id");
  lua_pushcfunction(lstate, &nlua_api_nvim_del_augroup_by_name);
  lua_setfield(lstate, -2, "nvim_del_augroup_by_name");
  lua_pushcfunction(lstate, &nlua_api_nvim_exec_autocmds);
  lua_setfield(lstate, -2, "nvim_exec_autocmds");
  lua_pushcfunction(lstate, &nlua_api_nvim_buf_line_count);
  lua_setfield(lstate, -2, "nvim_buf_line_count");
  lua_pushcfunction(lstate, &nlua_api_nvim_buf_attach);
  lua_setfield(lstate, -2, "nvim_buf_attach");
  lua_pushcfunction(lstate, &nlua_api_nvim__buf_redraw_range);
  lua_setfield(lstate, -2, "nvim__buf_redraw_range");
  lua_pushcfunction(lstate, &nlua_api_nvim_buf_get_lines);
  lua_setfield(lstate, -2, "nvim_buf_get_lines");
  lua_pushcfunction(lstate, &nlua_api_nvim_buf_set_lines);
  lua_setfield(lstate, -2, "nvim_buf_set_lines");
  lua_pushcfunction(lstate, &nlua_api_nvim_buf_set_text);
  lua_setfield(lstate, -2, "nvim_buf_set_text");
  lua_pushcfunction(lstate, &nlua_api_nvim_buf_get_text);
  lua_setfield(lstate, -2, "nvim_buf_get_text");
  lua_pushcfunction(lstate, &nlua_api_nvim_buf_get_offset);
  lua_setfield(lstate, -2, "nvim_buf_get_offset");
  lua_pushcfunction(lstate, &nlua_api_nvim_buf_get_var);
  lua_setfield(lstate, -2, "nvim_buf_get_var");
  lua_pushcfunction(lstate, &nlua_api_nvim_buf_get_changedtick);
  lua_setfield(lstate, -2, "nvim_buf_get_changedtick");
  lua_pushcfunction(lstate, &nlua_api_nvim_buf_get_keymap);
  lua_setfield(lstate, -2, "nvim_buf_get_keymap");
  lua_pushcfunction(lstate, &nlua_api_nvim_buf_set_keymap);
  lua_setfield(lstate, -2, "nvim_buf_set_keymap");
  lua_pushcfunction(lstate, &nlua_api_nvim_buf_del_keymap);
  lua_setfield(lstate, -2, "nvim_buf_del_keymap");
  lua_pushcfunction(lstate, &nlua_api_nvim_buf_set_var);
  lua_setfield(lstate, -2, "nvim_buf_set_var");
  lua_pushcfunction(lstate, &nlua_api_nvim_buf_del_var);
  lua_setfield(lstate, -2, "nvim_buf_del_var");
  lua_pushcfunction(lstate, &nlua_api_nvim_buf_get_name);
  lua_setfield(lstate, -2, "nvim_buf_get_name");
  lua_pushcfunction(lstate, &nlua_api_nvim_buf_set_name);
  lua_setfield(lstate, -2, "nvim_buf_set_name");
  lua_pushcfunction(lstate, &nlua_api_nvim_buf_is_loaded);
  lua_setfield(lstate, -2, "nvim_buf_is_loaded");
  lua_pushcfunction(lstate, &nlua_api_nvim_buf_delete);
  lua_setfield(lstate, -2, "nvim_buf_delete");
  lua_pushcfunction(lstate, &nlua_api_nvim_buf_is_valid);
  lua_setfield(lstate, -2, "nvim_buf_is_valid");
  lua_pushcfunction(lstate, &nlua_api_nvim_buf_del_mark);
  lua_setfield(lstate, -2, "nvim_buf_del_mark");
  lua_pushcfunction(lstate, &nlua_api_nvim_buf_set_mark);
  lua_setfield(lstate, -2, "nvim_buf_set_mark");
  lua_pushcfunction(lstate, &nlua_api_nvim_buf_get_mark);
  lua_setfield(lstate, -2, "nvim_buf_get_mark");
  lua_pushcfunction(lstate, &nlua_api_nvim_buf_call);
  lua_setfield(lstate, -2, "nvim_buf_call");
  lua_pushcfunction(lstate, &nlua_api_nvim__buf_stats);
  lua_setfield(lstate, -2, "nvim__buf_stats");
  lua_pushcfunction(lstate, &nlua_api_nvim_parse_cmd);
  lua_setfield(lstate, -2, "nvim_parse_cmd");
  lua_pushcfunction(lstate, &nlua_api_nvim_cmd);
  lua_setfield(lstate, -2, "nvim_cmd");
  lua_pushcfunction(lstate, &nlua_api_nvim_create_user_command);
  lua_setfield(lstate, -2, "nvim_create_user_command");
  lua_pushcfunction(lstate, &nlua_api_nvim_del_user_command);
  lua_setfield(lstate, -2, "nvim_del_user_command");
  lua_pushcfunction(lstate, &nlua_api_nvim_buf_create_user_command);
  lua_setfield(lstate, -2, "nvim_buf_create_user_command");
  lua_pushcfunction(lstate, &nlua_api_nvim_buf_del_user_command);
  lua_setfield(lstate, -2, "nvim_buf_del_user_command");
  lua_pushcfunction(lstate, &nlua_api_nvim_get_commands);
  lua_setfield(lstate, -2, "nvim_get_commands");
  lua_pushcfunction(lstate, &nlua_api_nvim_buf_get_commands);
  lua_setfield(lstate, -2, "nvim_buf_get_commands");
  lua_pushcfunction(lstate, &nlua_api_nvim_command_output);
  lua_setfield(lstate, -2, "nvim_command_output");
  lua_pushcfunction(lstate, &nlua_api_nvim_buf_get_number);
  lua_setfield(lstate, -2, "nvim_buf_get_number");
  lua_pushcfunction(lstate, &nlua_api_nvim_buf_clear_highlight);
  lua_setfield(lstate, -2, "nvim_buf_clear_highlight");
  lua_pushcfunction(lstate, &nlua_api_nvim_buf_set_virtual_text);
  lua_setfield(lstate, -2, "nvim_buf_set_virtual_text");
  lua_pushcfunction(lstate, &nlua_api_nvim_create_namespace);
  lua_setfield(lstate, -2, "nvim_create_namespace");
  lua_pushcfunction(lstate, &nlua_api_nvim_get_namespaces);
  lua_setfield(lstate, -2, "nvim_get_namespaces");
  lua_pushcfunction(lstate, &nlua_api_nvim_buf_get_extmark_by_id);
  lua_setfield(lstate, -2, "nvim_buf_get_extmark_by_id");
  lua_pushcfunction(lstate, &nlua_api_nvim_buf_get_extmarks);
  lua_setfield(lstate, -2, "nvim_buf_get_extmarks");
  lua_pushcfunction(lstate, &nlua_api_nvim_buf_set_extmark);
  lua_setfield(lstate, -2, "nvim_buf_set_extmark");
  lua_pushcfunction(lstate, &nlua_api_nvim_buf_del_extmark);
  lua_setfield(lstate, -2, "nvim_buf_del_extmark");
  lua_pushcfunction(lstate, &nlua_api_nvim_buf_add_highlight);
  lua_setfield(lstate, -2, "nvim_buf_add_highlight");
  lua_pushcfunction(lstate, &nlua_api_nvim_buf_clear_namespace);
  lua_setfield(lstate, -2, "nvim_buf_clear_namespace");
  lua_pushcfunction(lstate, &nlua_api_nvim_set_decoration_provider);
  lua_setfield(lstate, -2, "nvim_set_decoration_provider");
  lua_pushcfunction(lstate, &nlua_api_nvim_get_option_value);
  lua_setfield(lstate, -2, "nvim_get_option_value");
  lua_pushcfunction(lstate, &nlua_api_nvim_set_option_value);
  lua_setfield(lstate, -2, "nvim_set_option_value");
  lua_pushcfunction(lstate, &nlua_api_nvim_get_all_options_info);
  lua_setfield(lstate, -2, "nvim_get_all_options_info");
  lua_pushcfunction(lstate, &nlua_api_nvim_get_option_info);
  lua_setfield(lstate, -2, "nvim_get_option_info");
  lua_pushcfunction(lstate, &nlua_api_nvim_set_option);
  lua_setfield(lstate, -2, "nvim_set_option");
  lua_pushcfunction(lstate, &nlua_api_nvim_get_option);
  lua_setfield(lstate, -2, "nvim_get_option");
  lua_pushcfunction(lstate, &nlua_api_nvim_buf_get_option);
  lua_setfield(lstate, -2, "nvim_buf_get_option");
  lua_pushcfunction(lstate, &nlua_api_nvim_buf_set_option);
  lua_setfield(lstate, -2, "nvim_buf_set_option");
  lua_pushcfunction(lstate, &nlua_api_nvim_win_get_option);
  lua_setfield(lstate, -2, "nvim_win_get_option");
  lua_pushcfunction(lstate, &nlua_api_nvim_win_set_option);
  lua_setfield(lstate, -2, "nvim_win_set_option");
  lua_pushcfunction(lstate, &nlua_api_nvim_tabpage_list_wins);
  lua_setfield(lstate, -2, "nvim_tabpage_list_wins");
  lua_pushcfunction(lstate, &nlua_api_nvim_tabpage_get_var);
  lua_setfield(lstate, -2, "nvim_tabpage_get_var");
  lua_pushcfunction(lstate, &nlua_api_nvim_tabpage_set_var);
  lua_setfield(lstate, -2, "nvim_tabpage_set_var");
  lua_pushcfunction(lstate, &nlua_api_nvim_tabpage_del_var);
  lua_setfield(lstate, -2, "nvim_tabpage_del_var");
  lua_pushcfunction(lstate, &nlua_api_nvim_tabpage_get_win);
  lua_setfield(lstate, -2, "nvim_tabpage_get_win");
  lua_pushcfunction(lstate, &nlua_api_nvim_tabpage_get_number);
  lua_setfield(lstate, -2, "nvim_tabpage_get_number");
  lua_pushcfunction(lstate, &nlua_api_nvim_tabpage_is_valid);
  lua_setfield(lstate, -2, "nvim_tabpage_is_valid");
  lua_pushcfunction(lstate, &nlua_api_nvim_get_hl_by_name);
  lua_setfield(lstate, -2, "nvim_get_hl_by_name");
  lua_pushcfunction(lstate, &nlua_api_nvim_get_hl_by_id);
  lua_setfield(lstate, -2, "nvim_get_hl_by_id");
  lua_pushcfunction(lstate, &nlua_api_nvim_get_hl_id_by_name);
  lua_setfield(lstate, -2, "nvim_get_hl_id_by_name");
  lua_pushcfunction(lstate, &nlua_api_nvim__get_hl_defs);
  lua_setfield(lstate, -2, "nvim__get_hl_defs");
  lua_pushcfunction(lstate, &nlua_api_nvim_set_hl);
  lua_setfield(lstate, -2, "nvim_set_hl");
  lua_pushcfunction(lstate, &nlua_api_nvim_set_hl_ns);
  lua_setfield(lstate, -2, "nvim_set_hl_ns");
  lua_pushcfunction(lstate, &nlua_api_nvim_set_hl_ns_fast);
  lua_setfield(lstate, -2, "nvim_set_hl_ns_fast");
  lua_pushcfunction(lstate, &nlua_api_nvim_feedkeys);
  lua_setfield(lstate, -2, "nvim_feedkeys");
  lua_pushcfunction(lstate, &nlua_api_nvim_input);
  lua_setfield(lstate, -2, "nvim_input");
  lua_pushcfunction(lstate, &nlua_api_nvim_input_mouse);
  lua_setfield(lstate, -2, "nvim_input_mouse");
  lua_pushcfunction(lstate, &nlua_api_nvim_replace_termcodes);
  lua_setfield(lstate, -2, "nvim_replace_termcodes");
  lua_pushcfunction(lstate, &nlua_api_nvim_notify);
  lua_setfield(lstate, -2, "nvim_notify");
  lua_pushcfunction(lstate, &nlua_api_nvim_strwidth);
  lua_setfield(lstate, -2, "nvim_strwidth");
  lua_pushcfunction(lstate, &nlua_api_nvim_list_runtime_paths);
  lua_setfield(lstate, -2, "nvim_list_runtime_paths");
  lua_pushcfunction(lstate, &nlua_api_nvim__runtime_inspect);
  lua_setfield(lstate, -2, "nvim__runtime_inspect");
  lua_pushcfunction(lstate, &nlua_api_nvim_get_runtime_file);
  lua_setfield(lstate, -2, "nvim_get_runtime_file");
  lua_pushcfunction(lstate, &nlua_api_nvim__get_lib_dir);
  lua_setfield(lstate, -2, "nvim__get_lib_dir");
  lua_pushcfunction(lstate, &nlua_api_nvim__get_runtime);
  lua_setfield(lstate, -2, "nvim__get_runtime");
  lua_pushcfunction(lstate, &nlua_api_nvim_set_current_dir);
  lua_setfield(lstate, -2, "nvim_set_current_dir");
  lua_pushcfunction(lstate, &nlua_api_nvim_get_current_line);
  lua_setfield(lstate, -2, "nvim_get_current_line");
  lua_pushcfunction(lstate, &nlua_api_nvim_set_current_line);
  lua_setfield(lstate, -2, "nvim_set_current_line");
  lua_pushcfunction(lstate, &nlua_api_nvim_del_current_line);
  lua_setfield(lstate, -2, "nvim_del_current_line");
  lua_pushcfunction(lstate, &nlua_api_nvim_get_var);
  lua_setfield(lstate, -2, "nvim_get_var");
  lua_pushcfunction(lstate, &nlua_api_nvim_set_var);
  lua_setfield(lstate, -2, "nvim_set_var");
  lua_pushcfunction(lstate, &nlua_api_nvim_del_var);
  lua_setfield(lstate, -2, "nvim_del_var");
  lua_pushcfunction(lstate, &nlua_api_nvim_get_vvar);
  lua_setfield(lstate, -2, "nvim_get_vvar");
  lua_pushcfunction(lstate, &nlua_api_nvim_set_vvar);
  lua_setfield(lstate, -2, "nvim_set_vvar");
  lua_pushcfunction(lstate, &nlua_api_nvim_echo);
  lua_setfield(lstate, -2, "nvim_echo");
  lua_pushcfunction(lstate, &nlua_api_nvim_out_write);
  lua_setfield(lstate, -2, "nvim_out_write");
  lua_pushcfunction(lstate, &nlua_api_nvim_err_write);
  lua_setfield(lstate, -2, "nvim_err_write");
  lua_pushcfunction(lstate, &nlua_api_nvim_err_writeln);
  lua_setfield(lstate, -2, "nvim_err_writeln");
  lua_pushcfunction(lstate, &nlua_api_nvim_list_bufs);
  lua_setfield(lstate, -2, "nvim_list_bufs");
  lua_pushcfunction(lstate, &nlua_api_nvim_get_current_buf);
  lua_setfield(lstate, -2, "nvim_get_current_buf");
  lua_pushcfunction(lstate, &nlua_api_nvim_set_current_buf);
  lua_setfield(lstate, -2, "nvim_set_current_buf");
  lua_pushcfunction(lstate, &nlua_api_nvim_list_wins);
  lua_setfield(lstate, -2, "nvim_list_wins");
  lua_pushcfunction(lstate, &nlua_api_nvim_get_current_win);
  lua_setfield(lstate, -2, "nvim_get_current_win");
  lua_pushcfunction(lstate, &nlua_api_nvim_set_current_win);
  lua_setfield(lstate, -2, "nvim_set_current_win");
  lua_pushcfunction(lstate, &nlua_api_nvim_create_buf);
  lua_setfield(lstate, -2, "nvim_create_buf");
  lua_pushcfunction(lstate, &nlua_api_nvim_open_term);
  lua_setfield(lstate, -2, "nvim_open_term");
  lua_pushcfunction(lstate, &nlua_api_nvim_chan_send);
  lua_setfield(lstate, -2, "nvim_chan_send");
  lua_pushcfunction(lstate, &nlua_api_nvim_list_tabpages);
  lua_setfield(lstate, -2, "nvim_list_tabpages");
  lua_pushcfunction(lstate, &nlua_api_nvim_get_current_tabpage);
  lua_setfield(lstate, -2, "nvim_get_current_tabpage");
  lua_pushcfunction(lstate, &nlua_api_nvim_set_current_tabpage);
  lua_setfield(lstate, -2, "nvim_set_current_tabpage");
  lua_pushcfunction(lstate, &nlua_api_nvim_paste);
  lua_setfield(lstate, -2, "nvim_paste");
  lua_pushcfunction(lstate, &nlua_api_nvim_put);
  lua_setfield(lstate, -2, "nvim_put");
  lua_pushcfunction(lstate, &nlua_api_nvim_get_color_by_name);
  lua_setfield(lstate, -2, "nvim_get_color_by_name");
  lua_pushcfunction(lstate, &nlua_api_nvim_get_color_map);
  lua_setfield(lstate, -2, "nvim_get_color_map");
  lua_pushcfunction(lstate, &nlua_api_nvim_get_context);
  lua_setfield(lstate, -2, "nvim_get_context");
  lua_pushcfunction(lstate, &nlua_api_nvim_load_context);
  lua_setfield(lstate, -2, "nvim_load_context");
  lua_pushcfunction(lstate, &nlua_api_nvim_get_mode);
  lua_setfield(lstate, -2, "nvim_get_mode");
  lua_pushcfunction(lstate, &nlua_api_nvim_get_keymap);
  lua_setfield(lstate, -2, "nvim_get_keymap");
  lua_pushcfunction(lstate, &nlua_api_nvim_set_keymap);
  lua_setfield(lstate, -2, "nvim_set_keymap");
  lua_pushcfunction(lstate, &nlua_api_nvim_del_keymap);
  lua_setfield(lstate, -2, "nvim_del_keymap");
  lua_pushcfunction(lstate, &nlua_api_nvim_get_chan_info);
  lua_setfield(lstate, -2, "nvim_get_chan_info");
  lua_pushcfunction(lstate, &nlua_api_nvim_list_chans);
  lua_setfield(lstate, -2, "nvim_list_chans");
  lua_pushcfunction(lstate, &nlua_api_nvim__id);
  lua_setfield(lstate, -2, "nvim__id");
  lua_pushcfunction(lstate, &nlua_api_nvim__id_array);
  lua_setfield(lstate, -2, "nvim__id_array");
  lua_pushcfunction(lstate, &nlua_api_nvim__id_dictionary);
  lua_setfield(lstate, -2, "nvim__id_dictionary");
  lua_pushcfunction(lstate, &nlua_api_nvim__id_float);
  lua_setfield(lstate, -2, "nvim__id_float");
  lua_pushcfunction(lstate, &nlua_api_nvim__stats);
  lua_setfield(lstate, -2, "nvim__stats");
  lua_pushcfunction(lstate, &nlua_api_nvim_list_uis);
  lua_setfield(lstate, -2, "nvim_list_uis");
  lua_pushcfunction(lstate, &nlua_api_nvim_get_proc_children);
  lua_setfield(lstate, -2, "nvim_get_proc_children");
  lua_pushcfunction(lstate, &nlua_api_nvim_get_proc);
  lua_setfield(lstate, -2, "nvim_get_proc");
  lua_pushcfunction(lstate, &nlua_api_nvim_select_popupmenu_item);
  lua_setfield(lstate, -2, "nvim_select_popupmenu_item");
  lua_pushcfunction(lstate, &nlua_api_nvim__inspect_cell);
  lua_setfield(lstate, -2, "nvim__inspect_cell");
  lua_pushcfunction(lstate, &nlua_api_nvim__screenshot);
  lua_setfield(lstate, -2, "nvim__screenshot");
  lua_pushcfunction(lstate, &nlua_api_nvim__unpack);
  lua_setfield(lstate, -2, "nvim__unpack");
  lua_pushcfunction(lstate, &nlua_api_nvim_del_mark);
  lua_setfield(lstate, -2, "nvim_del_mark");
  lua_pushcfunction(lstate, &nlua_api_nvim_get_mark);
  lua_setfield(lstate, -2, "nvim_get_mark");
  lua_pushcfunction(lstate, &nlua_api_nvim_eval_statusline);
  lua_setfield(lstate, -2, "nvim_eval_statusline");
  lua_pushcfunction(lstate, &nlua_api_nvim_exec);
  lua_setfield(lstate, -2, "nvim_exec");
  lua_pushcfunction(lstate, &nlua_api_nvim_command);
  lua_setfield(lstate, -2, "nvim_command");
  lua_pushcfunction(lstate, &nlua_api_nvim_eval);
  lua_setfield(lstate, -2, "nvim_eval");
  lua_pushcfunction(lstate, &nlua_api_nvim_call_function);
  lua_setfield(lstate, -2, "nvim_call_function");
  lua_pushcfunction(lstate, &nlua_api_nvim_call_dict_function);
  lua_setfield(lstate, -2, "nvim_call_dict_function");
  lua_pushcfunction(lstate, &nlua_api_nvim_parse_expression);
  lua_setfield(lstate, -2, "nvim_parse_expression");
  lua_pushcfunction(lstate, &nlua_api_nvim_open_win);
  lua_setfield(lstate, -2, "nvim_open_win");
  lua_pushcfunction(lstate, &nlua_api_nvim_win_set_config);
  lua_setfield(lstate, -2, "nvim_win_set_config");
  lua_pushcfunction(lstate, &nlua_api_nvim_win_get_config);
  lua_setfield(lstate, -2, "nvim_win_get_config");
  lua_pushcfunction(lstate, &nlua_api_nvim_win_get_buf);
  lua_setfield(lstate, -2, "nvim_win_get_buf");
  lua_pushcfunction(lstate, &nlua_api_nvim_win_set_buf);
  lua_setfield(lstate, -2, "nvim_win_set_buf");
  lua_pushcfunction(lstate, &nlua_api_nvim_win_get_cursor);
  lua_setfield(lstate, -2, "nvim_win_get_cursor");
  lua_pushcfunction(lstate, &nlua_api_nvim_win_set_cursor);
  lua_setfield(lstate, -2, "nvim_win_set_cursor");
  lua_pushcfunction(lstate, &nlua_api_nvim_win_get_height);
  lua_setfield(lstate, -2, "nvim_win_get_height");
  lua_pushcfunction(lstate, &nlua_api_nvim_win_set_height);
  lua_setfield(lstate, -2, "nvim_win_set_height");
  lua_pushcfunction(lstate, &nlua_api_nvim_win_get_width);
  lua_setfield(lstate, -2, "nvim_win_get_width");
  lua_pushcfunction(lstate, &nlua_api_nvim_win_set_width);
  lua_setfield(lstate, -2, "nvim_win_set_width");
  lua_pushcfunction(lstate, &nlua_api_nvim_win_get_var);
  lua_setfield(lstate, -2, "nvim_win_get_var");
  lua_pushcfunction(lstate, &nlua_api_nvim_win_set_var);
  lua_setfield(lstate, -2, "nvim_win_set_var");
  lua_pushcfunction(lstate, &nlua_api_nvim_win_del_var);
  lua_setfield(lstate, -2, "nvim_win_del_var");
  lua_pushcfunction(lstate, &nlua_api_nvim_win_get_position);
  lua_setfield(lstate, -2, "nvim_win_get_position");
  lua_pushcfunction(lstate, &nlua_api_nvim_win_get_tabpage);
  lua_setfield(lstate, -2, "nvim_win_get_tabpage");
  lua_pushcfunction(lstate, &nlua_api_nvim_win_get_number);
  lua_setfield(lstate, -2, "nvim_win_get_number");
  lua_pushcfunction(lstate, &nlua_api_nvim_win_is_valid);
  lua_setfield(lstate, -2, "nvim_win_is_valid");
  lua_pushcfunction(lstate, &nlua_api_nvim_win_hide);
  lua_setfield(lstate, -2, "nvim_win_hide");
  lua_pushcfunction(lstate, &nlua_api_nvim_win_close);
  lua_setfield(lstate, -2, "nvim_win_close");
  lua_pushcfunction(lstate, &nlua_api_nvim_win_call);
  lua_setfield(lstate, -2, "nvim_win_call");
  lua_pushcfunction(lstate, &nlua_api_nvim_win_set_hl_ns);
  lua_setfield(lstate, -2, "nvim_win_set_hl_ns");
  lua_setfield(lstate, -2, "api");
}
