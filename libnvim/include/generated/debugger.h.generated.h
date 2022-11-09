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
DLLEXPORT void do_debug(char *cmd);
DLLEXPORT void ex_debug(exarg_T *eap);
DLLEXPORT void dbg_check_breakpoint(exarg_T *eap);
DLLEXPORT _Bool dbg_check_skipped(exarg_T *eap);
DLLEXPORT void ex_breakadd(exarg_T *eap);
DLLEXPORT void ex_debuggreedy(exarg_T *eap);
DLLEXPORT void ex_breakdel(exarg_T *eap);
DLLEXPORT void ex_breaklist(exarg_T *eap);
DLLEXPORT linenr_T dbg_find_breakpoint(_Bool file, char *fname, linenr_T after);
DLLEXPORT _Bool has_profiling(_Bool file, char *fname, _Bool *fp);
DLLEXPORT void dbg_breakpoint(char *name, linenr_T lnum);
#include "nvim/func_attr.h"
