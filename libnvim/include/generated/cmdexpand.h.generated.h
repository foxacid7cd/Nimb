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
DLLEXPORT int nextwild(expand_T *xp, int type, int options, _Bool escape);
DLLEXPORT void cmdline_pum_display(_Bool changed_array);
DLLEXPORT _Bool cmdline_pum_active(void);
DLLEXPORT void cmdline_pum_remove(void);
DLLEXPORT void cmdline_pum_cleanup(CmdlineInfo *cclp);
DLLEXPORT char *ExpandOne(expand_T *xp, char *str, char *orig, int options, int mode);
DLLEXPORT void ExpandInit(expand_T *xp) FUNC_ATTR_NONNULL_ALL;
DLLEXPORT void ExpandCleanup(expand_T *xp);
DLLEXPORT int showmatches(expand_T *xp, int wildmenu);
DLLEXPORT char *sm_gettail(char *s, _Bool eager);
DLLEXPORT char *addstar(char *fname, size_t len, int context) FUNC_ATTR_NONNULL_RET;
DLLEXPORT void set_expand_context(expand_T *xp);
DLLEXPORT void set_cmd_context(expand_T *xp, char_u *str, int len, int col, int use_ccline);
DLLEXPORT int expand_cmdline(expand_T *xp, const char_u *str, int col, int *matchcount, char ***matches);
DLLEXPORT void globpath(char *path, char *file, garray_T *ga, int expand_options);
DLLEXPORT int wildmenu_translate_key(CmdlineInfo *cclp, int key, expand_T *xp, int did_wild_list);
DLLEXPORT int wildmenu_process_key(CmdlineInfo *cclp, int key, expand_T *xp);
DLLEXPORT void wildmenu_cleanup(CmdlineInfo *cclp);
DLLEXPORT void f_getcompletion(typval_T *argvars, typval_T *rettv, EvalFuncData fptr);
#include "nvim/func_attr.h"
