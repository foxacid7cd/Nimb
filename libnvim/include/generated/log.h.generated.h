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
DLLEXPORT void log_init(void);
DLLEXPORT void log_lock(void);
DLLEXPORT void log_unlock(void);
DLLEXPORT _Bool logmsg(int log_level, const char *context, const char *func_name, int line_num, _Bool eol, const char *fmt, ...) FUNC_ATTR_UNUSED FUNC_ATTR_PRINTF(6, 7);
DLLEXPORT void log_uv_handles(void *loop);
DLLEXPORT FILE *open_log_file(void);
DLLEXPORT void log_callstack_to_file(FILE *log_file, const char *const func_name, const int line_num);
DLLEXPORT void log_callstack(const char *const func_name, const int line_num);
#include "nvim/func_attr.h"
