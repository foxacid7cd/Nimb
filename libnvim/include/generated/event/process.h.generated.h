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
DLLEXPORT int process_spawn(Process *proc, _Bool in, _Bool out, _Bool err) FUNC_ATTR_NONNULL_ALL;
DLLEXPORT void process_teardown(Loop *loop) FUNC_ATTR_NONNULL_ALL;
DLLEXPORT void process_close_streams(Process *proc) FUNC_ATTR_NONNULL_ALL;
DLLEXPORT int process_wait(Process *proc, int ms, MultiQueue *events) FUNC_ATTR_NONNULL_ARG(1);
DLLEXPORT void process_stop(Process *proc) FUNC_ATTR_NONNULL_ALL;
DLLEXPORT void process_free(Process *proc) FUNC_ATTR_NONNULL_ALL;
#include "nvim/func_attr.h"
