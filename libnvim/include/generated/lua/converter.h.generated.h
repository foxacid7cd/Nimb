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
DLLEXPORT _Bool nlua_pop_typval(lua_State *lstate, typval_T *ret_tv);
DLLEXPORT _Bool nlua_push_typval(lua_State *lstate, typval_T *const tv, _Bool special);
DLLEXPORT void nlua_push_String(lua_State *lstate, const String s, _Bool special) FUNC_ATTR_NONNULL_ALL;
DLLEXPORT void nlua_push_Integer(lua_State *lstate, const Integer n, _Bool special) FUNC_ATTR_NONNULL_ALL;
DLLEXPORT void nlua_push_Float(lua_State *lstate, const Float f, _Bool special) FUNC_ATTR_NONNULL_ALL;
DLLEXPORT void nlua_push_Boolean(lua_State *lstate, const Boolean b, _Bool special) FUNC_ATTR_NONNULL_ALL;
DLLEXPORT void nlua_push_Dictionary(lua_State *lstate, const Dictionary dict, _Bool special) FUNC_ATTR_NONNULL_ALL;
DLLEXPORT void nlua_push_Array(lua_State *lstate, const Array array, _Bool special) FUNC_ATTR_NONNULL_ALL;
DLLEXPORT void nlua_push_Buffer(lua_State *lstate, const Buffer item, _Bool special) FUNC_ATTR_NONNULL_ALL;
DLLEXPORT void nlua_push_Window(lua_State *lstate, const Window item, _Bool special) FUNC_ATTR_NONNULL_ALL;
DLLEXPORT void nlua_push_Tabpage(lua_State *lstate, const Tabpage item, _Bool special) FUNC_ATTR_NONNULL_ALL;
DLLEXPORT void nlua_push_Object(lua_State *lstate, const Object obj, _Bool special) FUNC_ATTR_NONNULL_ALL;
DLLEXPORT String nlua_pop_String(lua_State *lstate, Error *err) FUNC_ATTR_NONNULL_ALL FUNC_ATTR_WARN_UNUSED_RESULT;
DLLEXPORT Integer nlua_pop_Integer(lua_State *lstate, Error *err) FUNC_ATTR_NONNULL_ALL FUNC_ATTR_WARN_UNUSED_RESULT;
DLLEXPORT Boolean nlua_pop_Boolean(lua_State *lstate, Error *err) FUNC_ATTR_NONNULL_ALL FUNC_ATTR_WARN_UNUSED_RESULT;
DLLEXPORT Float nlua_pop_Float(lua_State *lstate, Error *err) FUNC_ATTR_NONNULL_ALL FUNC_ATTR_WARN_UNUSED_RESULT;
DLLEXPORT Array nlua_pop_Array(lua_State *lstate, Error *err) FUNC_ATTR_NONNULL_ALL FUNC_ATTR_WARN_UNUSED_RESULT;
DLLEXPORT Dictionary nlua_pop_Dictionary(lua_State *lstate, _Bool ref, Error *err) FUNC_ATTR_NONNULL_ALL FUNC_ATTR_WARN_UNUSED_RESULT;
DLLEXPORT Object nlua_pop_Object(lua_State *const lstate, _Bool ref, Error *const err);
DLLEXPORT LuaRef nlua_pop_LuaRef(lua_State *const lstate, Error *err);
DLLEXPORT Buffer nlua_pop_Buffer(lua_State *lstate, Error *err) FUNC_ATTR_NONNULL_ALL FUNC_ATTR_WARN_UNUSED_RESULT;
DLLEXPORT Window nlua_pop_Window(lua_State *lstate, Error *err) FUNC_ATTR_NONNULL_ALL FUNC_ATTR_WARN_UNUSED_RESULT;
DLLEXPORT Tabpage nlua_pop_Tabpage(lua_State *lstate, Error *err) FUNC_ATTR_NONNULL_ALL FUNC_ATTR_WARN_UNUSED_RESULT;
DLLEXPORT void nlua_init_types(lua_State *const lstate);
DLLEXPORT void nlua_pop_keydict(lua_State *L, void *retval, field_hash hashy, Error *err);
#include "nvim/func_attr.h"
