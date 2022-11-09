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
DLLEXPORT void state_enter(VimState *s);
DLLEXPORT void state_handle_k_event(void);
DLLEXPORT _Bool virtual_active(void);
DLLEXPORT int get_real_state(void);
DLLEXPORT void get_mode(char *buf);
DLLEXPORT void may_trigger_modechanged(void);
#include "nvim/func_attr.h"
