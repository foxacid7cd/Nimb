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
DLLEXPORT char *get_mess_lang(void);
DLLEXPORT void set_lang_var(void);
DLLEXPORT void init_locale(void);
DLLEXPORT void ex_language(exarg_T *eap);
DLLEXPORT char *get_lang_arg(expand_T *xp, int idx);
DLLEXPORT char *get_locales(expand_T *xp, int idx);
#include "nvim/func_attr.h"
