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
DLLEXPORT void tslua_init(lua_State *L);
DLLEXPORT int tslua_has_language(lua_State *L);
DLLEXPORT int tslua_add_language(lua_State *L);
DLLEXPORT int tslua_remove_lang(lua_State *L);
DLLEXPORT int tslua_inspect_lang(lua_State *L);
DLLEXPORT int tslua_push_parser(lua_State *L);
DLLEXPORT void push_tree(lua_State *L, TSTree *tree, _Bool do_copy);
DLLEXPORT int tslua_parse_query(lua_State *L);
#include "nvim/func_attr.h"
