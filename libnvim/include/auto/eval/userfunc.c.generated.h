#define DEFINE_FUNC_ATTRIBUTES
#include "nvim/func_attr.h"
#undef DEFINE_FUNC_ATTRIBUTES
static int get_function_args(char **argp, char_u endchar, garray_T *newargs, int *varargs, garray_T *default_args, _Bool skip);
static void register_closure(ufunc_T *fp);
static void set_ufunc_name(ufunc_T *fp, char *name);
static inline _Bool eval_fname_sid(const char *const name) FUNC_ATTR_PURE FUNC_ATTR_ALWAYS_INLINE FUNC_ATTR_WARN_UNUSED_RESULT FUNC_ATTR_NONNULL_ALL;
static char *fname_trans_sid(const char *const name, char *const fname_buf, char **const tofree, int *const error) FUNC_ATTR_NONNULL_ALL FUNC_ATTR_WARN_UNUSED_RESULT;
static void cat_func_name(char_u *buf, ufunc_T *fp);
static void add_nr_var(dict_T *dp, dictitem_T *v, char *name, varnumber_T nr);
static void free_funccal(funccall_T *fc);
static void free_funccal_contents(funccall_T *fc);
static void cleanup_function_call(funccall_T *fc);
static void funccal_unref(funccall_T *fc, ufunc_T *fp, _Bool force);
static _Bool func_remove(ufunc_T *fp);
static void func_clear_items(ufunc_T *fp);
static void func_clear(ufunc_T *fp, _Bool force);
static void func_free(ufunc_T *fp);
static void func_clear_free(ufunc_T *fp, _Bool force);
static _Bool func_name_refcount(const char_u *name);
static int call_user_func_check(ufunc_T *fp, int argcount, typval_T *argvars, typval_T *rettv, funcexe_T *funcexe, dict_T *selfdict) FUNC_ATTR_NONNULL_ARG(1, 3, 4, 5);
static _Bool builtin_function(const char *name, int len);
static void user_func_error(int error, const char_u *name) FUNC_ATTR_NONNULL_ALL;
static void argv_add_base(typval_T *const basetv, typval_T **const argvars, int *const argcount, typval_T *const new_argvars, int *const argv_base) FUNC_ATTR_NONNULL_ARG(2, 3, 4, 5);
static void list_func_head(ufunc_T *fp, int indent, _Bool force);
static void list_functions(regmatch_T *regmatch);
static inline _Bool fc_referenced(const funccall_T *const fc) FUNC_ATTR_ALWAYS_INLINE FUNC_ATTR_PURE FUNC_ATTR_WARN_UNUSED_RESULT FUNC_ATTR_NONNULL_ALL;
static int can_free_funccal(funccall_T *fc, int copyID);
static _Bool set_ref_in_funccal(funccall_T *fc, int copyID);
#include "nvim/func_attr.h"
