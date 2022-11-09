#define DEFINE_FUNC_ATTRIBUTES
#include "nvim/func_attr.h"
#undef DEFINE_FUNC_ATTRIBUTES
static int eval1_emsg(char **arg, typval_T *rettv, _Bool evaluate) FUNC_ATTR_NONNULL_ARG(1, 2);
static int eval_func(char **const arg, char *const name, const int name_len, typval_T *const rettv, const _Bool evaluate, typval_T *const basetv) FUNC_ATTR_NONNULL_ARG(1, 2, 4);
static int eval2(char **arg, typval_T *rettv, int evaluate);
static int eval3(char **arg, typval_T *rettv, int evaluate);
static int eval4(char **arg, typval_T *rettv, int evaluate);
static int eval5(char **arg, typval_T *rettv, int evaluate);
static int eval6(char **arg, typval_T *rettv, int evaluate, int want_string) FUNC_ATTR_NO_SANITIZE_UNDEFINED;
static int eval7(char **arg, typval_T *rettv, int evaluate, int want_string);
static int eval7_leader(typval_T *const rettv, const char *const start_leader, const char **const end_leaderp) FUNC_ATTR_NONNULL_ALL;
static int call_func_rettv(char **const arg, typval_T *const rettv, const _Bool evaluate, dict_T *const selfdict, typval_T *const basetv, const char *const lua_funcname) FUNC_ATTR_NONNULL_ARG(1, 2);
static int eval_lambda(char **const arg, typval_T *const rettv, const _Bool evaluate, const _Bool verbose) FUNC_ATTR_NONNULL_ALL;
static int eval_method(char **const arg, typval_T *const rettv, const _Bool evaluate, const _Bool verbose) FUNC_ATTR_NONNULL_ALL;
static int eval_index(char **arg, typval_T *rettv, int evaluate, int verbose);
static int get_string_tv(char **arg, typval_T *rettv, int evaluate);
static int get_lit_string_tv(char **arg, typval_T *rettv, int evaluate);
static void partial_free(partial_T *pt);
static int get_list_tv(char **arg, typval_T *rettv, int evaluate);
static int free_unref_items(int copyID);
static inline _Bool set_ref_in_fmark(fmark_T fm, int copyID) FUNC_ATTR_WARN_UNUSED_RESULT;
static inline _Bool set_ref_list(list_T *list, int copyID) FUNC_ATTR_WARN_UNUSED_RESULT;
static inline _Bool set_ref_dict(dict_T *dict, int copyID) FUNC_ATTR_WARN_UNUSED_RESULT;
static int get_literal_key(char **arg, typval_T *tv) FUNC_ATTR_NONNULL_ALL;
static int eval_dict(char **arg, typval_T *rettv, int evaluate, _Bool literal);
static int get_env_tv(char **arg, typval_T *rettv, int evaluate);
static int filter_map_one(typval_T *tv, typval_T *expr, int map, int *remp) FUNC_ATTR_NONNULL_ARG(1, 2);
static list_T *string_to_list(const char *str, size_t len, const _Bool keepempty);
static _Bool set_ref_in_callback_reader(CallbackReader *reader, int copyID, ht_stack_T **ht_stack, list_stack_T **list_stack);
static void timer_close_cb(TimeWatcher *tw, void *data);
static void timer_decref(timer_T *timer);
static char *make_expanded_name(const char *in_start, char *expr_start, char *expr_end, char *in_end);
static void check_vars(const char *name, size_t len);
static _Bool tv_is_luafunc(typval_T *tv);
static var_flavour_T var_flavour(char *varname) FUNC_ATTR_PURE;
#include "nvim/func_attr.h"
