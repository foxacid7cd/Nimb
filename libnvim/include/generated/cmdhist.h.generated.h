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
DLLEXPORT int get_hislen(void);
DLLEXPORT histentry_T *get_histentry(int hist_type);
DLLEXPORT void set_histentry(int hist_type, histentry_T *entry);
DLLEXPORT int *get_hisidx(int hist_type);
DLLEXPORT int *get_hisnum(int hist_type);
DLLEXPORT HistoryType hist_char2type(const int c) FUNC_ATTR_CONST FUNC_ATTR_WARN_UNUSED_RESULT;
DLLEXPORT char *get_history_arg(expand_T *xp, int idx);
DLLEXPORT void init_history(void);
DLLEXPORT void add_to_history(int histype, char *new_entry, int in_map, int sep);
DLLEXPORT int clr_history(const int histype);
DLLEXPORT void f_histadd(typval_T *argvars, typval_T *rettv, EvalFuncData fptr);
DLLEXPORT void f_histdel(typval_T *argvars, typval_T *rettv, EvalFuncData fptr);
DLLEXPORT void f_histget(typval_T *argvars, typval_T *rettv, EvalFuncData fptr);
DLLEXPORT void f_histnr(typval_T *argvars, typval_T *rettv, EvalFuncData fptr);
DLLEXPORT void ex_history(exarg_T *eap);
DLLEXPORT const void *hist_iter(const void *const iter, const uint8_t history_type, const _Bool zero, histentry_T *const hist) FUNC_ATTR_WARN_UNUSED_RESULT FUNC_ATTR_NONNULL_ARG(4);
DLLEXPORT histentry_T *hist_get_array(const uint8_t history_type, int **const new_hisidx, int **const new_hisnum) FUNC_ATTR_WARN_UNUSED_RESULT FUNC_ATTR_NONNULL_ALL;
#include "nvim/func_attr.h"
