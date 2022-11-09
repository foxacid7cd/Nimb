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
DLLEXPORT UI *tui_start(void);
DLLEXPORT void tui_enable_extkeys(TUIData *data);
DLLEXPORT CursorShape tui_cursor_decode_shape(const char *shape_str);
#include "nvim/func_attr.h"
