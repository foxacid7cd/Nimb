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
DLLEXPORT proftime_T profile_start(void) FUNC_ATTR_WARN_UNUSED_RESULT;
DLLEXPORT proftime_T profile_end(proftime_T tm) FUNC_ATTR_WARN_UNUSED_RESULT;
DLLEXPORT const char *profile_msg(proftime_T tm) FUNC_ATTR_WARN_UNUSED_RESULT;
DLLEXPORT proftime_T profile_setlimit(int64_t msec) FUNC_ATTR_WARN_UNUSED_RESULT;
DLLEXPORT _Bool profile_passed_limit(proftime_T tm) FUNC_ATTR_WARN_UNUSED_RESULT;
DLLEXPORT proftime_T profile_zero(void) FUNC_ATTR_CONST;
DLLEXPORT proftime_T profile_divide(proftime_T tm, int count) FUNC_ATTR_CONST;
DLLEXPORT proftime_T profile_add(proftime_T tm1, proftime_T tm2) FUNC_ATTR_CONST;
DLLEXPORT proftime_T profile_sub(proftime_T tm1, proftime_T tm2) FUNC_ATTR_CONST;
DLLEXPORT proftime_T profile_self(proftime_T self, proftime_T total, proftime_T children) FUNC_ATTR_CONST;
DLLEXPORT proftime_T profile_get_wait(void) FUNC_ATTR_PURE;
DLLEXPORT void profile_set_wait(proftime_T wait);
DLLEXPORT proftime_T profile_sub_wait(proftime_T tm, proftime_T tma) FUNC_ATTR_PURE;
DLLEXPORT _Bool profile_equal(proftime_T tm1, proftime_T tm2) FUNC_ATTR_CONST;
DLLEXPORT int64_t profile_signed(proftime_T tm) FUNC_ATTR_CONST;
DLLEXPORT int profile_cmp(proftime_T tm1, proftime_T tm2) FUNC_ATTR_CONST;
DLLEXPORT void profile_reset(void);
DLLEXPORT void ex_profile(exarg_T *eap);
DLLEXPORT char *get_profile_name(expand_T *xp, int idx) FUNC_ATTR_PURE;
DLLEXPORT void set_context_in_profile_cmd(expand_T *xp, const char *arg);
DLLEXPORT void prof_inchar_enter(void);
DLLEXPORT void prof_inchar_exit(void);
DLLEXPORT _Bool prof_def_func(void) FUNC_ATTR_PURE;
DLLEXPORT void func_do_profile(ufunc_T *fp);
DLLEXPORT void prof_child_enter(proftime_T *tm);
DLLEXPORT void prof_child_exit(proftime_T *tm);
DLLEXPORT void func_line_start(void *cookie);
DLLEXPORT void func_line_exec(void *cookie);
DLLEXPORT void func_line_end(void *cookie);
DLLEXPORT void profile_init(scriptitem_T *si);
DLLEXPORT void script_prof_save(proftime_T *tm);
DLLEXPORT void script_prof_restore(const proftime_T *tm);
DLLEXPORT void profile_dump(void);
DLLEXPORT void script_line_start(void);
DLLEXPORT void script_line_exec(void);
DLLEXPORT void script_line_end(void);
DLLEXPORT void time_push(proftime_T *rel, proftime_T *start);
DLLEXPORT void time_pop(proftime_T tp);
DLLEXPORT void time_start(const char *message);
DLLEXPORT void time_msg(const char *mesg, const proftime_T *start);
#include "nvim/func_attr.h"
