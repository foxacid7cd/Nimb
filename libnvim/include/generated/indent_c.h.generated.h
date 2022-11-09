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
DLLEXPORT pos_T *find_start_comment(int ind_maxcomment);
DLLEXPORT int is_pos_in_string(const char_u *line, colnr_T col);
DLLEXPORT _Bool cin_is_cinword(const char *line);
DLLEXPORT _Bool cin_islabel(void);
DLLEXPORT _Bool cin_iscase(const char_u *s, _Bool strict);
DLLEXPORT _Bool cin_isscopedecl(const char_u *p);
DLLEXPORT void parse_cino(buf_T *buf);
DLLEXPORT int get_c_indent(void);
DLLEXPORT void do_c_expr_indent(void);
#include "nvim/func_attr.h"
