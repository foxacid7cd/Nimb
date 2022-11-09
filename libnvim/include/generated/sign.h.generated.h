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
DLLEXPORT void init_signs(void);
DLLEXPORT SignTextAttrs *sign_get_attr(int idx, SignTextAttrs sattrs[], int max_signs);
DLLEXPORT int buf_get_signattrs(buf_T *buf, linenr_T lnum, SignTextAttrs sattrs[], HlPriAttr *num_attrs, HlPriAttr *line_attrs, HlPriAttr *cul_attrs);
DLLEXPORT void buf_delete_signs(buf_T *buf, char *group);
DLLEXPORT void sign_mark_adjust(linenr_T line1, linenr_T line2, linenr_T amount, linenr_T amount_after);
DLLEXPORT void ex_sign(exarg_T *eap);
DLLEXPORT list_T *get_buffer_signs(buf_T *buf) FUNC_ATTR_NONNULL_RET FUNC_ATTR_NONNULL_ALL FUNC_ATTR_WARN_UNUSED_RESULT;
DLLEXPORT void free_signs(void);
DLLEXPORT char *get_sign_name(expand_T *xp, int idx);
DLLEXPORT void set_context_in_sign_cmd(expand_T *xp, char *arg);
DLLEXPORT void f_sign_define(typval_T *argvars, typval_T *rettv, EvalFuncData fptr);
DLLEXPORT void f_sign_getdefined(typval_T *argvars, typval_T *rettv, EvalFuncData fptr);
DLLEXPORT void f_sign_getplaced(typval_T *argvars, typval_T *rettv, EvalFuncData fptr);
DLLEXPORT void f_sign_jump(typval_T *argvars, typval_T *rettv, EvalFuncData fptr);
DLLEXPORT void f_sign_place(typval_T *argvars, typval_T *rettv, EvalFuncData fptr);
DLLEXPORT void f_sign_placelist(typval_T *argvars, typval_T *rettv, EvalFuncData fptr);
DLLEXPORT void f_sign_undefine(typval_T *argvars, typval_T *rettv, EvalFuncData fptr);
DLLEXPORT void f_sign_unplace(typval_T *argvars, typval_T *rettv, EvalFuncData fptr);
DLLEXPORT void f_sign_unplacelist(typval_T *argvars, typval_T *rettv, EvalFuncData fptr);
#include "nvim/func_attr.h"
