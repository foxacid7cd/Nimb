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
DLLEXPORT void ex_let(exarg_T *eap);
DLLEXPORT void ex_const(exarg_T *eap);
DLLEXPORT int ex_let_vars(char *arg_start, typval_T *tv, int copy, int semicolon, int var_count, int is_const, char *op);
DLLEXPORT const char *skip_var_list(const char *arg, int *var_count, int *semicolon);
DLLEXPORT void list_hashtable_vars(hashtab_T *ht, const char *prefix, int empty, int *first);
DLLEXPORT void ex_unlet(exarg_T *eap);
DLLEXPORT void ex_lockvar(exarg_T *eap);
DLLEXPORT int do_unlet(const char *const name, const size_t name_len, const _Bool forceit) FUNC_ATTR_NONNULL_ALL;
DLLEXPORT int get_var_tv(const char *name, int len, typval_T *rettv, dictitem_T **dip, _Bool verbose, _Bool no_autoload);
DLLEXPORT char_u *get_var_value(const char *const name);
DLLEXPORT void vars_clear(hashtab_T *ht);
DLLEXPORT void vars_clear_ext(hashtab_T *ht, int free_val);
DLLEXPORT void delete_var(hashtab_T *ht, hashitem_T *hi);
DLLEXPORT void set_var(const char *name, const size_t name_len, typval_T *const tv, const _Bool copy) FUNC_ATTR_NONNULL_ALL;
DLLEXPORT void set_var_const(const char *name, const size_t name_len, typval_T *const tv, const _Bool copy, const _Bool is_const) FUNC_ATTR_NONNULL_ALL;
DLLEXPORT _Bool var_check_ro(const int flags, const char *name, size_t name_len) FUNC_ATTR_WARN_UNUSED_RESULT FUNC_ATTR_NONNULL_ALL;
DLLEXPORT _Bool var_check_fixed(const int flags, const char *name, size_t name_len) FUNC_ATTR_WARN_UNUSED_RESULT FUNC_ATTR_NONNULL_ALL;
DLLEXPORT _Bool var_wrong_func_name(const char *const name, const _Bool new_var) FUNC_ATTR_NONNULL_ALL FUNC_ATTR_WARN_UNUSED_RESULT;
DLLEXPORT _Bool valid_varname(const char *varname) FUNC_ATTR_NONNULL_ALL FUNC_ATTR_WARN_UNUSED_RESULT;
DLLEXPORT _Bool var_exists(const char *var) FUNC_ATTR_NONNULL_ALL;
DLLEXPORT void f_gettabvar(typval_T *argvars, typval_T *rettv, EvalFuncData fptr);
DLLEXPORT void f_gettabwinvar(typval_T *argvars, typval_T *rettv, EvalFuncData fptr);
DLLEXPORT void f_getwinvar(typval_T *argvars, typval_T *rettv, EvalFuncData fptr);
DLLEXPORT void f_getbufvar(typval_T *argvars, typval_T *rettv, EvalFuncData fptr);
DLLEXPORT void f_settabvar(typval_T *argvars, typval_T *rettv, EvalFuncData fptr);
DLLEXPORT void f_settabwinvar(typval_T *argvars, typval_T *rettv, EvalFuncData fptr);
DLLEXPORT void f_setwinvar(typval_T *argvars, typval_T *rettv, EvalFuncData fptr);
DLLEXPORT void f_setbufvar(typval_T *argvars, typval_T *rettv, EvalFuncData fptr);
#include "nvim/func_attr.h"
