#define DEFINE_FUNC_ATTRIBUTES
#include "nvim/func_attr.h"
#undef DEFINE_FUNC_ATTRIBUTES
static void set_option_default(int opt_idx, int opt_flags);
static void set_options_default(int opt_flags);
static void set_string_default(const char *name, char *val, _Bool allocated) FUNC_ATTR_NONNULL_ALL;
static char *find_dup_item(char *origval, const char *newval, uint32_t flags) FUNC_ATTR_NONNULL_ARG(2);
static int do_set_string(int opt_idx, int opt_flags, char **argp, int nextchar, set_op_T op_arg, uint32_t flags, char *varp_arg, char *errbuf, size_t errbuflen, int *value_checked, char **errmsg);
static char *option_expand(int opt_idx, char *val);
static void didset_options(void);
static void didset_options2(void);
static uint32_t *insecure_flag(win_T *const wp, int opt_idx, int opt_flags);
static char *set_bool_option(const int opt_idx, char_u *const varp, const int value, const int opt_flags);
static char *set_num_option(int opt_idx, char_u *varp, long value, char *errbuf, size_t errbuflen, int opt_flags);
static int find_key_option(const char *arg, _Bool has_lt);
static void showoptions(int all, int opt_flags);
static int optval_default(vimoption_T *p, const char_u *varp);
static void showoneopt(vimoption_T *p, int opt_flags);
static int put_setstring(FILE *fd, char *cmd, char *name, char **valuep, uint64_t flags);
static int put_setnum(FILE *fd, char *cmd, char *name, long *valuep);
static int put_setbool(FILE *fd, char *cmd, char *name, int value);
static char_u *get_varp(vimoption_T *p);
static char *copy_option_val(const char *val);
static void check_winopt(winopt_T *wop);
static void init_buf_opt_idx(void);
static void option_value2string(vimoption_T *opp, int scope);
static int wc_use_keyname(const char_u *varp, long *wcp);
static void paste_option_changed(void);
static Dictionary vimoption2dict(vimoption_T *opt);
#include "nvim/func_attr.h"
