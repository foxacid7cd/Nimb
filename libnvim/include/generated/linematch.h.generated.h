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
DLLEXPORT void fastforward_buf_to_lnum(const char **s, long lnum);
DLLEXPORT size_t linematch_nbuffers(const char **diff_blk, const int *diff_len, const size_t ndiffs, int **decisions, _Bool iwhite);
#include "nvim/func_attr.h"
