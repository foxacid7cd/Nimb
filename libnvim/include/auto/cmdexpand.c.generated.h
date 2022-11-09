#define DEFINE_FUNC_ATTRIBUTES
#include "nvim/func_attr.h"
#undef DEFINE_FUNC_ATTRIBUTES
static int sort_func_compare(const void *s1, const void *s2);
static void ExpandEscape(expand_T *xp, char_u *str, int numfiles, char **files, int options);
static char *get_next_or_prev_match(int mode, expand_T *xp, int *p_findex, char *orig_save);
static char *ExpandOne_start(int mode, expand_T *xp, char *str, int options);
static char *find_longest_match(expand_T *xp, int options);
static _Bool expand_showtail(expand_T *xp);
static const char *set_cmd_index(const char *cmd, exarg_T *eap, expand_T *xp, int *complp);
static void set_context_for_wildcard_arg(exarg_T *eap, const char *arg, _Bool usefilter, expand_T *xp, int *complp);
static const char *set_context_by_cmdname(const char *cmd, cmdidx_T cmdidx, const char *arg, uint32_t argt, int context, expand_T *xp, _Bool forceit);
static const char *set_one_cmd_context(expand_T *xp, const char *buff);
static int expand_files_and_dirs(expand_T *xp, char *pat, char ***file, int *num_file, int flags, int options);
static char *get_behave_arg(expand_T *xp FUNC_ATTR_UNUSED, int idx);
static char *get_messages_arg(expand_T *xp FUNC_ATTR_UNUSED, int idx);
static char *get_mapclear_arg(expand_T *xp FUNC_ATTR_UNUSED, int idx);
static char *get_healthcheck_names(expand_T *xp FUNC_ATTR_UNUSED, int idx);
static int ExpandOther(expand_T *xp, regmatch_T *rmp, int *num_file, char ***file);
static int ExpandFromContext(expand_T *xp, char_u *pat, int *num_file, char ***file, int options);
static void ExpandGeneric(expand_T *xp, regmatch_T *regmatch, int *num_file, char ***file, CompleteListItemGetter func, int escaped);
static void expand_shellcmd(char *filepat, int *num_file, char ***file, int flagsarg) FUNC_ATTR_NONNULL_ALL;
static void *call_user_expand_func(user_expand_func_T user_expand_func, expand_T *xp, int *num_file, char ***file) FUNC_ATTR_NONNULL_ALL;
static int ExpandUserDefined(expand_T *xp, regmatch_T *regmatch, int *num_file, char ***file);
static int ExpandUserList(expand_T *xp, int *num_file, char ***file);
static int ExpandUserLua(expand_T *xp, int *num_file, char ***file);
static void cmdline_del(CmdlineInfo *cclp, int from);
#include "nvim/func_attr.h"
