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
DLLEXPORT Object nvim_get_option_value(String name, Dict(option) *opts, Error *err) FUNC_API_SINCE(9);
DLLEXPORT void nvim_set_option_value(String name, Object value, Dict(option) *opts, Error *err) FUNC_API_SINCE(9);
DLLEXPORT Dictionary nvim_get_all_options_info(Error *err) FUNC_API_SINCE(7);
DLLEXPORT Dictionary nvim_get_option_info(String name, Error *err) FUNC_API_SINCE(7);
DLLEXPORT void nvim_set_option(uint64_t channel_id, String name, Object value, Error *err) FUNC_API_SINCE(1);
DLLEXPORT Object nvim_get_option(String name, Error *err) FUNC_API_SINCE(1);
DLLEXPORT Object nvim_buf_get_option(Buffer buffer, String name, Error *err) FUNC_API_SINCE(1);
DLLEXPORT void nvim_buf_set_option(uint64_t channel_id, Buffer buffer, String name, Object value, Error *err) FUNC_API_SINCE(1);
DLLEXPORT Object nvim_win_get_option(Window window, String name, Error *err) FUNC_API_SINCE(1);
DLLEXPORT void nvim_win_set_option(uint64_t channel_id, Window window, String name, Object value, Error *err) FUNC_API_SINCE(1);
DLLEXPORT Object get_option_from(void *from, int type, String name, Error *err);
DLLEXPORT void set_option_to(uint64_t channel_id, void *to, int type, String name, Object value, Error *err);
#include "nvim/func_attr.h"
