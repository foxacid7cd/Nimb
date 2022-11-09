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
DLLEXPORT String nvim_command_output(uint64_t channel_id, String command, Error *err) FUNC_API_SINCE(1) FUNC_API_DEPRECATED_SINCE(7);
DLLEXPORT Object nvim_execute_lua(String code, Array args, Error *err) FUNC_API_SINCE(3) FUNC_API_DEPRECATED_SINCE(7) FUNC_API_REMOTE_ONLY;
DLLEXPORT Integer nvim_buf_get_number(Buffer buffer, Error *err) FUNC_API_SINCE(1) FUNC_API_DEPRECATED_SINCE(2);
DLLEXPORT void nvim_buf_clear_highlight(Buffer buffer, Integer ns_id, Integer line_start, Integer line_end, Error *err) FUNC_API_SINCE(1) FUNC_API_DEPRECATED_SINCE(7);
DLLEXPORT Integer nvim_buf_set_virtual_text(Buffer buffer, Integer src_id, Integer line, Array chunks, Dictionary opts, Error *err) FUNC_API_SINCE(5) FUNC_API_DEPRECATED_SINCE(8);
DLLEXPORT void buffer_insert(Buffer buffer, Integer lnum, ArrayOf(String) lines, Error *err) FUNC_API_DEPRECATED_SINCE(1);
DLLEXPORT String buffer_get_line(Buffer buffer, Integer index, Error *err) FUNC_API_DEPRECATED_SINCE(1);
DLLEXPORT void buffer_set_line(Buffer buffer, Integer index, String line, Error *err) FUNC_API_DEPRECATED_SINCE(1);
DLLEXPORT void buffer_del_line(Buffer buffer, Integer index, Error *err) FUNC_API_DEPRECATED_SINCE(1);
DLLEXPORT ArrayOf(String) buffer_get_line_slice(Buffer buffer, Integer start, Integer end, Boolean include_start, Boolean include_end, Error *err) FUNC_API_DEPRECATED_SINCE(1);
DLLEXPORT void buffer_set_line_slice(Buffer buffer, Integer start, Integer end, Boolean include_start, Boolean include_end, ArrayOf(String) replacement, Error *err) FUNC_API_DEPRECATED_SINCE(1);
DLLEXPORT Object buffer_set_var(Buffer buffer, String name, Object value, Error *err) FUNC_API_DEPRECATED_SINCE(1);
DLLEXPORT Object buffer_del_var(Buffer buffer, String name, Error *err) FUNC_API_DEPRECATED_SINCE(1);
DLLEXPORT Object window_set_var(Window window, String name, Object value, Error *err) FUNC_API_DEPRECATED_SINCE(1);
DLLEXPORT Object window_del_var(Window window, String name, Error *err) FUNC_API_DEPRECATED_SINCE(1);
DLLEXPORT Object tabpage_set_var(Tabpage tabpage, String name, Object value, Error *err) FUNC_API_DEPRECATED_SINCE(1);
DLLEXPORT Object tabpage_del_var(Tabpage tabpage, String name, Error *err) FUNC_API_DEPRECATED_SINCE(1);
DLLEXPORT Object vim_set_var(String name, Object value, Error *err) FUNC_API_DEPRECATED_SINCE(1);
DLLEXPORT Object vim_del_var(String name, Error *err) FUNC_API_DEPRECATED_SINCE(1);
#include "nvim/func_attr.h"
