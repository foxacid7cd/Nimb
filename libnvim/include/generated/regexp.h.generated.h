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
DLLEXPORT int re_multiline(const regprog_T *prog) FUNC_ATTR_NONNULL_ALL;
DLLEXPORT char *skip_regexp(char *startp, int delim, int magic);
DLLEXPORT char *skip_regexp_err(char *startp, int delim, int magic);
DLLEXPORT char *skip_regexp_ex(char *startp, int dirc, int magic, char **newp, int *dropped);
DLLEXPORT reg_extmatch_T *ref_extmatch(reg_extmatch_T *em);
DLLEXPORT void unref_extmatch(reg_extmatch_T *em);
DLLEXPORT char *regtilde(char *source, int magic, _Bool preview);
DLLEXPORT int vim_regsub(regmatch_T *rmp, char_u *source, typval_T *expr, char_u *dest, int destlen, int flags);
DLLEXPORT int vim_regsub_multi(regmmatch_T *rmp, linenr_T lnum, char_u *source, char_u *dest, int destlen, int flags);
DLLEXPORT char *reg_submatch(int no);
DLLEXPORT list_T *reg_submatch_list(int no);
DLLEXPORT regprog_T *vim_regcomp(char *expr_arg, int re_flags);
DLLEXPORT void vim_regfree(regprog_T *prog);
DLLEXPORT _Bool vim_regexec_prog(regprog_T **prog, _Bool ignore_case, char_u *line, colnr_T col);
DLLEXPORT _Bool vim_regexec(regmatch_T *rmp, char *line, colnr_T col);
DLLEXPORT _Bool vim_regexec_nl(regmatch_T *rmp, char_u *line, colnr_T col);
DLLEXPORT long vim_regexec_multi(regmmatch_T *rmp, win_T *win, buf_T *buf, linenr_T lnum, colnr_T col, proftime_T *tm, int *timed_out) FUNC_ATTR_NONNULL_ARG(1);
#include "nvim/func_attr.h"
