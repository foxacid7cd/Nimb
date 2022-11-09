#define DEFINE_FUNC_ATTRIBUTES
#include "nvim/func_attr.h"
#undef DEFINE_FUNC_ATTRIBUTES
static list_T *heredoc_get(exarg_T *eap, char *cmd);
static void ex_let_const(exarg_T *eap, const _Bool is_const);
static const char *skip_var_one(const char *arg);
static void list_glob_vars(int *first);
static void list_buf_vars(int *first);
static void list_win_vars(int *first);
static void list_tab_vars(int *first);
static const char *list_arg_vars(exarg_T *eap, const char *arg, int *first);
static char *ex_let_one(char *arg, typval_T *const tv, const _Bool copy, const _Bool is_const, const char *const endchars, const char *const op) FUNC_ATTR_NONNULL_ARG(1, 2) FUNC_ATTR_WARN_UNUSED_RESULT;
static void ex_unletlock(exarg_T *eap, char *argstart, int deep, ex_unletlock_callback callback) FUNC_ATTR_NONNULL_ALL;
static int do_unlet_var(lval_T *lp, char *name_end, exarg_T *eap, int deep FUNC_ATTR_UNUSED) FUNC_ATTR_NONNULL_ALL;
static int do_lock_var(lval_T *lp, char *name_end FUNC_ATTR_UNUSED, exarg_T *eap, int deep) FUNC_ATTR_NONNULL_ARG(1, 3);
static void list_one_var(dictitem_T *v, const char *prefix, int *first);
static void list_one_var_a(const char *prefix, const char *name, const ptrdiff_t name_len, const VarType type, const char *string, int *first);
static void get_var_from(const char *varname, typval_T *rettv, typval_T *deftv, int htname, tabpage_T *tp, win_T *win, buf_T *buf);
static void getwinvar(typval_T *argvars, typval_T *rettv, int off);
static void set_option_from_tv(const char *varname, typval_T *varp);
static void setwinvar(typval_T *argvars, typval_T *rettv, int off);
#include "nvim/func_attr.h"
