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
DLLEXPORT int win_line(win_T *wp, linenr_T lnum, int startrow, int endrow, _Bool nochange, _Bool number_only, foldinfo_T foldinfo, DecorProviders *providers, char **provider_err);
#include "nvim/func_attr.h"
