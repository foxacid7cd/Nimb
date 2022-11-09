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
DLLEXPORT String nvim_exec(uint64_t channel_id, String src, Boolean output, Error *err) FUNC_API_SINCE(7);
DLLEXPORT void nvim_command(String command, Error *err) FUNC_API_SINCE(1);
DLLEXPORT Object nvim_eval(String expr, Error *err) FUNC_API_SINCE(1);
DLLEXPORT Object nvim_call_function(String fn, Array args, Error *err) FUNC_API_SINCE(1);
DLLEXPORT Object nvim_call_dict_function(Object dict, String fn, Array args, Error *err) FUNC_API_SINCE(4);
DLLEXPORT Dictionary nvim_parse_expression(String expr, String flags, Boolean highlight, Error *err) FUNC_API_SINCE(4) FUNC_API_FAST;
#include "nvim/func_attr.h"
