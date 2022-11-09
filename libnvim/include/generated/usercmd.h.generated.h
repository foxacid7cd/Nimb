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
DLLEXPORT char *find_ucmd(exarg_T *eap, char *p, int *full, expand_T *xp, int *complp);
DLLEXPORT const char *set_context_in_user_cmd(expand_T *xp, const char *arg_in);
DLLEXPORT char *expand_user_command_name(int idx);
DLLEXPORT char *get_user_commands(expand_T *xp FUNC_ATTR_UNUSED, int idx) FUNC_ATTR_PURE FUNC_ATTR_WARN_UNUSED_RESULT;
DLLEXPORT char *get_user_command_name(int idx, int cmdidx);
DLLEXPORT char *get_user_cmd_addr_type(expand_T *xp, int idx);
DLLEXPORT char *get_user_cmd_flags(expand_T *xp, int idx);
DLLEXPORT char *get_user_cmd_nargs(expand_T *xp, int idx);
DLLEXPORT char *get_user_cmd_complete(expand_T *xp, int idx);
DLLEXPORT int cmdcomplete_str_to_type(const char *complete_str);
DLLEXPORT int parse_addr_type_arg(char *value, int vallen, cmd_addr_T *addr_type_arg) FUNC_ATTR_NONNULL_ALL;
DLLEXPORT int parse_compl_arg(const char *value, int vallen, int *complp, uint32_t *argt, char **compl_arg) FUNC_ATTR_NONNULL_ALL;
DLLEXPORT char *uc_validate_name(char *name);
DLLEXPORT int uc_add_command(char *name, size_t name_len, const char *rep, uint32_t argt, long def, int flags, int compl, char *compl_arg, LuaRef compl_luaref, LuaRef preview_luaref, cmd_addr_T addr_type, LuaRef luaref, _Bool force) FUNC_ATTR_NONNULL_ARG(1, 3);
DLLEXPORT void ex_command(exarg_T *eap);
DLLEXPORT void ex_comclear(exarg_T *eap);
DLLEXPORT void free_ucmd(ucmd_T *cmd);
DLLEXPORT void uc_clear(garray_T *gap);
DLLEXPORT void ex_delcommand(exarg_T *eap);
DLLEXPORT _Bool uc_split_args_iter(const char *arg, size_t arglen, size_t *end, char *buf, size_t *len);
DLLEXPORT size_t add_win_cmd_modifiers(char *buf, const cmdmod_T *cmod, _Bool *multi_mods);
DLLEXPORT size_t uc_mods(char *buf, const cmdmod_T *cmod, _Bool quote);
DLLEXPORT int do_ucmd(exarg_T *eap, _Bool preview);
DLLEXPORT Dictionary commands_array(buf_T *buf);
#include "nvim/func_attr.h"
