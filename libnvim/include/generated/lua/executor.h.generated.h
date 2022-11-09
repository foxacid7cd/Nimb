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
DLLEXPORT LuaRef nlua_get_nil_ref(lua_State *lstate) FUNC_ATTR_NONNULL_ALL;
DLLEXPORT LuaRef nlua_get_empty_dict_ref(lua_State *lstate) FUNC_ATTR_NONNULL_ALL;
DLLEXPORT int nlua_get_global_ref_count(void);
DLLEXPORT void nlua_init(void);
DLLEXPORT void nlua_free_all_mem(void);
DLLEXPORT int nlua_in_fast_event(lua_State *lstate);
DLLEXPORT int nlua_call(lua_State *lstate);
DLLEXPORT LuaRef nlua_ref(lua_State *lstate, nlua_ref_state_t *ref_state, int index);
DLLEXPORT LuaRef nlua_ref_global(lua_State *lstate, int index);
DLLEXPORT void nlua_unref(lua_State *lstate, nlua_ref_state_t *ref_state, LuaRef ref);
DLLEXPORT void nlua_unref_global(lua_State *lstate, LuaRef ref);
DLLEXPORT void api_free_luaref(LuaRef ref);
DLLEXPORT void nlua_pushref(lua_State *lstate, LuaRef ref);
DLLEXPORT LuaRef api_new_luaref(LuaRef original_ref);
DLLEXPORT void nlua_typval_eval(const String str, typval_T *const arg, typval_T *const ret_tv) FUNC_ATTR_NONNULL_ALL;
DLLEXPORT void nlua_typval_call(const char *str, size_t len, typval_T *const args, int argcount, typval_T *ret_tv) FUNC_ATTR_NONNULL_ALL;
DLLEXPORT void nlua_call_user_expand_func(expand_T *xp, typval_T *ret_tv) FUNC_ATTR_NONNULL_ALL;
DLLEXPORT int nlua_source_using_linegetter(LineGetter fgetline, void *cookie, char *name);
DLLEXPORT int typval_exec_lua_callable(LuaRef lua_cb, int argcount, typval_T *argvars, typval_T *rettv);
DLLEXPORT Object nlua_exec(const String str, const Array args, Error *err);
DLLEXPORT _Bool nlua_ref_is_function(LuaRef ref);
DLLEXPORT Object nlua_call_ref(LuaRef ref, const char *name, Array args, _Bool retval, Error *err);
DLLEXPORT _Bool nlua_is_deferred_safe(void);
DLLEXPORT void ex_lua(exarg_T *const eap) FUNC_ATTR_NONNULL_ALL;
DLLEXPORT void ex_luado(exarg_T *const eap) FUNC_ATTR_NONNULL_ALL;
DLLEXPORT void ex_luafile(exarg_T *const eap) FUNC_ATTR_NONNULL_ALL;
DLLEXPORT _Bool nlua_exec_file(const char *path) FUNC_ATTR_NONNULL_ALL;
DLLEXPORT int tslua_get_language_version(lua_State *L);
DLLEXPORT int tslua_get_minimum_language_version(lua_State *L);
DLLEXPORT int nlua_expand_pat(expand_T *xp, char *pat, int *num_results, char ***results);
DLLEXPORT _Bool nlua_is_table_from_lua(typval_T *const arg);
DLLEXPORT char_u *nlua_register_table_as_callable(typval_T *const arg);
DLLEXPORT void nlua_execute_on_key(int c);
DLLEXPORT void nlua_set_sctx(sctx_T *current);
DLLEXPORT int nlua_do_ucmd(ucmd_T *cmd, exarg_T *eap, _Bool preview);
DLLEXPORT char *nlua_funcref_str(LuaRef ref);
#include "nvim/func_attr.h"
