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
DLLEXPORT int spell_check_sps(void);
DLLEXPORT void spell_suggest(int count);
DLLEXPORT void spell_suggest_list(garray_T *gap, char_u *word, int maxcount, _Bool need_cap, _Bool interactive);
#include "nvim/func_attr.h"
