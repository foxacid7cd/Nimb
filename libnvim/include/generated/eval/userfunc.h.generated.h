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
DLLEXPORT void func_init(void);
DLLEXPORT hashtab_T *func_tbl_get(void);
DLLEXPORT char_u *get_lambda_name(void);
DLLEXPORT int get_lambda_tv(char **arg, typval_T *rettv, _Bool evaluate);
DLLEXPORT char_u *deref_func_name(const char *name, int *lenp, partial_T **const partialp, _Bool no_autoload) FUNC_ATTR_NONNULL_ARG(1, 2);
DLLEXPORT void emsg_funcname(char *ermsg, const char_u *name);
DLLEXPORT int get_func_tv(const char_u *name, int len, typval_T *rettv, char **arg, funcexe_T *funcexe);
DLLEXPORT ufunc_T *find_func(const char_u *name);
DLLEXPORT void call_user_func(ufunc_T *fp, int argcount, typval_T *argvars, typval_T *rettv, linenr_T firstline, linenr_T lastline, dict_T *selfdict) FUNC_ATTR_NONNULL_ARG(1, 3, 4);
DLLEXPORT void save_funccal(funccal_entry_T *entry);
DLLEXPORT void restore_funccal(void);
DLLEXPORT funccall_T *get_current_funccal(void);
DLLEXPORT void set_current_funccal(funccall_T *fc);
DLLEXPORT int func_call(char_u *name, typval_T *args, partial_T *partial, dict_T *selfdict, typval_T *rettv);
DLLEXPORT varnumber_T callback_call_retnr(Callback *callback, int argcount, typval_T *argvars);
DLLEXPORT int call_func(const char *funcname, int len, typval_T *rettv, int argcount_in, typval_T *argvars_in, funcexe_T *funcexe) FUNC_ATTR_NONNULL_ARG(1, 3, 5, 6);
DLLEXPORT char_u *trans_function_name(char **pp, _Bool skip, int flags, funcdict_T *fdp, partial_T **partial) FUNC_ATTR_NONNULL_ARG(1);
DLLEXPORT char *save_function_name(char **name, _Bool skip, int flags, funcdict_T *fudi);
DLLEXPORT void ex_function(exarg_T *eap);
DLLEXPORT int eval_fname_script(const char *const p);
DLLEXPORT _Bool translated_function_exists(const char *name);
DLLEXPORT _Bool function_exists(const char *const name, _Bool no_deref);
DLLEXPORT char *get_user_func_name(expand_T *xp, int idx);
DLLEXPORT void ex_delfunction(exarg_T *eap);
DLLEXPORT void func_unref(char_u *name);
DLLEXPORT void func_ptr_unref(ufunc_T *fp);
DLLEXPORT void func_ref(char_u *name);
DLLEXPORT void func_ptr_ref(ufunc_T *fp);
DLLEXPORT void ex_return(exarg_T *eap);
DLLEXPORT void ex_call(exarg_T *eap);
DLLEXPORT int do_return(exarg_T *eap, int reanimate, int is_cmd, void *rettv);
DLLEXPORT char *get_return_cmd(void *rettv);
DLLEXPORT char *get_func_line(int c, void *cookie, int indent, _Bool do_concat);
DLLEXPORT int func_has_ended(void *cookie);
DLLEXPORT int func_has_abort(void *cookie);
DLLEXPORT void make_partial(dict_T *const selfdict, typval_T *const rettv);
DLLEXPORT char_u *func_name(void *cookie);
DLLEXPORT linenr_T *func_breakpoint(void *cookie);
DLLEXPORT int *func_dbg_tick(void *cookie);
DLLEXPORT int func_level(void *cookie);
DLLEXPORT int current_func_returned(void);
DLLEXPORT _Bool free_unref_funccal(int copyID, int testing);
DLLEXPORT funccall_T *get_funccal(void);
DLLEXPORT hashtab_T *get_funccal_local_ht(void);
DLLEXPORT dictitem_T *get_funccal_local_var(void);
DLLEXPORT hashtab_T *get_funccal_args_ht(void);
DLLEXPORT dictitem_T *get_funccal_args_var(void);
DLLEXPORT void list_func_vars(int *first);
DLLEXPORT dict_T *get_current_funccal_dict(hashtab_T *ht);
DLLEXPORT hashitem_T *find_hi_in_scoped_ht(const char *name, hashtab_T **pht);
DLLEXPORT dictitem_T *find_var_in_scoped_ht(const char *name, const size_t namelen, int no_autoload);
DLLEXPORT _Bool set_ref_in_previous_funccal(int copyID);
DLLEXPORT _Bool set_ref_in_call_stack(int copyID);
DLLEXPORT _Bool set_ref_in_functions(int copyID);
DLLEXPORT _Bool set_ref_in_func_args(int copyID);
DLLEXPORT _Bool set_ref_in_func(char_u *name, ufunc_T *fp_in, int copyID);
DLLEXPORT char_u *register_luafunc(LuaRef ref);
#include "nvim/func_attr.h"
