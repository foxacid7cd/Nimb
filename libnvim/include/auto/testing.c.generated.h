#define DEFINE_FUNC_ATTRIBUTES
#include "nvim/func_attr.h"
#undef DEFINE_FUNC_ATTRIBUTES
static void prepare_assert_error(garray_T *gap);
static void ga_concat_esc(garray_T *gap, const char_u *p, int clen) FUNC_ATTR_NONNULL_ALL;
static void ga_concat_shorten_esc(garray_T *gap, const char_u *str) FUNC_ATTR_NONNULL_ARG(1);
static void fill_assert_error(garray_T *gap, typval_T *opt_msg_tv, char_u *exp_str, typval_T *exp_tv_arg, typval_T *got_tv_arg, assert_type_T atype);
static int assert_equal_common(typval_T *argvars, assert_type_T atype) FUNC_ATTR_NONNULL_ALL;
static int assert_match_common(typval_T *argvars, assert_type_T atype) FUNC_ATTR_NONNULL_ALL;
static int assert_bool(typval_T *argvars, _Bool is_true) FUNC_ATTR_NONNULL_ALL;
static void assert_append_cmd_or_arg(garray_T *gap, typval_T *argvars, const char *cmd) FUNC_ATTR_NONNULL_ALL;
static int assert_beeps(typval_T *argvars, _Bool no_beep) FUNC_ATTR_NONNULL_ALL;
static int assert_equalfile(typval_T *argvars) FUNC_ATTR_NONNULL_ALL;
static int assert_inrange(typval_T *argvars) FUNC_ATTR_NONNULL_ALL;
#include "nvim/func_attr.h"
