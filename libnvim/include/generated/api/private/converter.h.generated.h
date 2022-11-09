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
DLLEXPORT Object vim_to_object(typval_T *obj);
DLLEXPORT _Bool object_to_vim(Object obj, typval_T *tv, Error *err);
#include "nvim/func_attr.h"
