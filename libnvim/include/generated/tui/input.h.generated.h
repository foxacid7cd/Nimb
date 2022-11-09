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
DLLEXPORT void tinput_init(TermInput *input, Loop *loop);
DLLEXPORT void tinput_destroy(TermInput *input);
DLLEXPORT void tinput_start(TermInput *input);
DLLEXPORT void tinput_stop(TermInput *input);
#include "nvim/func_attr.h"
