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
DLLEXPORT int eexe_mod_op(typval_T *const tv1, const typval_T *const tv2, const char *const op) FUNC_ATTR_NONNULL_ALL FUNC_ATTR_NO_SANITIZE_UNDEFINED;
#include "nvim/func_attr.h"
