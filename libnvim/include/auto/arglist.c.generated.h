#define DEFINE_FUNC_ATTRIBUTES
#include "nvim/func_attr.h"
#undef DEFINE_FUNC_ATTRIBUTES
static int check_arglist_locked(void);
static char *do_one_arg(char *str);
static void get_arglist(garray_T *gap, char *str, int escaped);
static void alist_check_arg_idx(void);
static void alist_add_list(int count, char **files, int after, _Bool will_edit) FUNC_ATTR_NONNULL_ALL;
static void arglist_del_files(garray_T *alist_ga);
static int do_arglist(char *str, int what, int after, _Bool will_edit) FUNC_ATTR_NONNULL_ALL;
static void arg_all_close_unused_windows(arg_all_state_T *aall);
static void arg_all_open_windows(arg_all_state_T *aall, int count);
static void do_arg_all(int count, int forceit, int keep_tabs);
static void get_arglist_as_rettv(aentry_T *arglist, int argcount, typval_T *rettv);
#include "nvim/func_attr.h"
