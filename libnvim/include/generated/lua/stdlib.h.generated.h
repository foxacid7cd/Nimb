#define DEFINE_FUNC_ATTRIBUTES
#include "nvim/func_attr.h"
#undef DEFINE_FUNC_ATTRIBUTES
#ifndef DLLEXPORT
#  ifdef MSWIN
#    define DLLEXPORT __declspec(dllexport)
#  else
#    define DLLEXPORT
#  endif
#endif
DLLEXPORT int nlua_str_utfindex(lua_State *const lstate) FUNC_ATTR_NONNULL_ALL;
DLLEXPORT int nlua_str_byteindex(lua_State *const lstate) FUNC_ATTR_NONNULL_ALL;
DLLEXPORT int nlua_regex(lua_State *lstate);
DLLEXPORT int nlua_setvar(lua_State *lstate);
DLLEXPORT int nlua_getvar(lua_State *lstate);
DLLEXPORT void nlua_state_add_stdlib(lua_State *const lstate, _Bool is_thread);
DLLEXPORT void nlua_push_errstr(lua_State *L, const char *fmt, ...);
#include "nvim/func_attr.h"
