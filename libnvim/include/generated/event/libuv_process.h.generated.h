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
DLLEXPORT int libuv_process_spawn(LibuvProcess *uvproc) FUNC_ATTR_NONNULL_ALL;
DLLEXPORT void libuv_process_close(LibuvProcess *uvproc) FUNC_ATTR_NONNULL_ARG(1);
#include "nvim/func_attr.h"
