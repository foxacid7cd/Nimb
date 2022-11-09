#define DEFINE_FUNC_ATTRIBUTES
#include "nvim/func_attr.h"
#undef DEFINE_FUNC_ATTRIBUTES
static void augroup_map_del(int id, char *name);
static inline const char *get_deleted_augroup(void) FUNC_ATTR_ALWAYS_INLINE;
static void aupat_show(AutoPat *ap, event_T event, int previous_group);
static void au_show_for_all_events(int group, char *pat);
static void au_show_for_event(int group, event_T event, char *pat);
static void aupat_del(AutoPat *ap);
static void aupat_remove_cmds(AutoPat *ap);
static void aucmd_del(AutoCmd *ac);
static void au_cleanup(void);
static _Bool event_ignored(event_T event) FUNC_ATTR_PURE FUNC_ATTR_WARN_UNUSED_RESULT;
static _Bool call_autocmd_callback(const AutoCmd *ac, const AutoPatCmd *apc);
static char *arg_event_skip(char *arg, int have_group);
static int arg_augroup_get(char **argp);
static _Bool arg_autocmd_flag_get(_Bool *flag, char **cmd_ptr, char *pattern, int len);
static void focusgained_event(void **argv);
static void do_autocmd_focusgained(_Bool gained);
static void define_autocmd(event_T event, char *pat, char *group, _Bool once, _Bool nested, char *cmd);
#include "nvim/func_attr.h"
