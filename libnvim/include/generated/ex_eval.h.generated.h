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
DLLEXPORT int aborting(void);
DLLEXPORT void update_force_abort(void);
DLLEXPORT int should_abort(int retcode);
DLLEXPORT int aborted_in_try(void) FUNC_ATTR_PURE;
DLLEXPORT _Bool cause_errthrow(const char *mesg, _Bool severe, _Bool *ignore) FUNC_ATTR_NONNULL_ALL;
DLLEXPORT void free_global_msglist(void);
DLLEXPORT void do_errthrow(cstack_T *cstack, char *cmdname);
DLLEXPORT int do_intthrow(cstack_T *cstack);
DLLEXPORT char *get_exception_string(void *value, except_type_T type, char *cmdname, int *should_free);
DLLEXPORT void discard_current_exception(void);
DLLEXPORT void report_make_pending(int pending, void *value);
DLLEXPORT void report_resume_pending(int pending, void *value);
DLLEXPORT void report_discard_pending(int pending, void *value);
DLLEXPORT void ex_eval(exarg_T *eap);
DLLEXPORT void ex_if(exarg_T *eap);
DLLEXPORT void ex_endif(exarg_T *eap);
DLLEXPORT void ex_else(exarg_T *eap);
DLLEXPORT void ex_while(exarg_T *eap);
DLLEXPORT void ex_continue(exarg_T *eap);
DLLEXPORT void ex_break(exarg_T *eap);
DLLEXPORT void ex_endwhile(exarg_T *eap);
DLLEXPORT void ex_throw(exarg_T *eap);
DLLEXPORT void do_throw(cstack_T *cstack);
DLLEXPORT void ex_try(exarg_T *eap);
DLLEXPORT void ex_catch(exarg_T *eap);
DLLEXPORT void ex_finally(exarg_T *eap);
DLLEXPORT void ex_endtry(exarg_T *eap);
DLLEXPORT void enter_cleanup(cleanup_T *csp);
DLLEXPORT void leave_cleanup(cleanup_T *csp);
DLLEXPORT int cleanup_conditionals(cstack_T *cstack, int searched_cond, int inclusive);
DLLEXPORT void rewind_conditionals(cstack_T *cstack, int idx, int cond_type, int *cond_level);
DLLEXPORT void ex_endfunction(exarg_T *eap);
DLLEXPORT int has_loop_cmd(char *p);
#include "nvim/func_attr.h"
