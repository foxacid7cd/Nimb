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
DLLEXPORT int do_digraph(int c);
DLLEXPORT char_u *get_digraph_for_char(int val_arg);
DLLEXPORT int get_digraph(_Bool cmdline);
DLLEXPORT int digraph_get(int char1, int char2, _Bool meta_char) FUNC_ATTR_PURE;
DLLEXPORT _Bool check_digraph_chars_valid(int char1, int char2);
DLLEXPORT void putdigraph(char *str);
DLLEXPORT void listdigraphs(_Bool use_headers);
DLLEXPORT void digraph_getlist_common(_Bool list_all, typval_T *rettv);
DLLEXPORT void f_digraph_get(typval_T *argvars, typval_T *rettv, EvalFuncData fptr);
DLLEXPORT void f_digraph_getlist(typval_T *argvars, typval_T *rettv, EvalFuncData fptr);
DLLEXPORT void f_digraph_set(typval_T *argvars, typval_T *rettv, EvalFuncData fptr);
DLLEXPORT void f_digraph_setlist(typval_T *argvars, typval_T *rettv, EvalFuncData fptr);
DLLEXPORT char *keymap_init(void);
DLLEXPORT void ex_loadkeymap(exarg_T *eap);
DLLEXPORT void keymap_ga_clear(garray_T *kmap_ga);
#include "nvim/func_attr.h"
