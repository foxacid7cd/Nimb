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
DLLEXPORT _Bool arabic_maycombine(int two) FUNC_ATTR_PURE;
DLLEXPORT _Bool arabic_combine(int one, int two) FUNC_ATTR_PURE;
DLLEXPORT int arabic_shape(int c, int *ccp, int *c1p, int prev_c, int prev_c1, int next_c);
#include "nvim/func_attr.h"
