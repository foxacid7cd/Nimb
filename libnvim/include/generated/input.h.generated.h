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
DLLEXPORT int ask_yesno(const char *const str, const _Bool direct);
DLLEXPORT int get_keystroke(MultiQueue *events);
DLLEXPORT int get_number(int colon, int *mouse_used);
DLLEXPORT int prompt_for_number(int *mouse_used);
#include "nvim/func_attr.h"
