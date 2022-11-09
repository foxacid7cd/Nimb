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
DLLEXPORT void ex_loadview(exarg_T *eap);
DLLEXPORT void ex_mkrc(exarg_T *eap);
DLLEXPORT int put_eol(FILE *fd);
DLLEXPORT int put_line(FILE *fd, char *s);
#include "nvim/func_attr.h"
