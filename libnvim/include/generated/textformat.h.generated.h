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
DLLEXPORT _Bool has_format_option(int x) FUNC_ATTR_PURE FUNC_ATTR_WARN_UNUSED_RESULT;
DLLEXPORT void internal_format(int textwidth, int second_indent, int flags, _Bool format_only, int c);
DLLEXPORT void auto_format(_Bool trailblank, _Bool prev_line);
DLLEXPORT void check_auto_format(_Bool end_insert);
DLLEXPORT int comp_textwidth(_Bool ff);
DLLEXPORT void op_format(oparg_T *oap, _Bool keep_cursor);
DLLEXPORT void op_formatexpr(oparg_T *oap);
DLLEXPORT int fex_format(linenr_T lnum, long count, int c);
DLLEXPORT void format_lines(linenr_T line_count, _Bool avoid_fex);
#include "nvim/func_attr.h"
