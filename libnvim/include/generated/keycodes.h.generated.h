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
DLLEXPORT int name_to_mod_mask(int c) FUNC_ATTR_CONST FUNC_ATTR_WARN_UNUSED_RESULT;
DLLEXPORT int simplify_key(const int key, int *modifiers) FUNC_ATTR_WARN_UNUSED_RESULT FUNC_ATTR_NONNULL_ALL;
DLLEXPORT int handle_x_keys(const int key) FUNC_ATTR_CONST FUNC_ATTR_WARN_UNUSED_RESULT;
DLLEXPORT char_u *get_special_key_name(int c, int modifiers);
DLLEXPORT unsigned int trans_special(const char_u **const srcp, const size_t src_len, char_u *const dst, const int flags, const _Bool escape_ks, _Bool *const did_simplify) FUNC_ATTR_NONNULL_ARG(1, 3) FUNC_ATTR_WARN_UNUSED_RESULT;
DLLEXPORT unsigned int special_to_buf(int key, int modifiers, _Bool escape_ks, char_u *dst);
DLLEXPORT int find_special_key(const char_u **const srcp, const size_t src_len, int *const modp, const int flags, _Bool *const did_simplify) FUNC_ATTR_WARN_UNUSED_RESULT FUNC_ATTR_NONNULL_ARG(1, 3);
DLLEXPORT int find_special_key_in_table(int c);
DLLEXPORT int get_special_key_code(const char_u *name) FUNC_ATTR_NONNULL_ALL FUNC_ATTR_PURE FUNC_ATTR_WARN_UNUSED_RESULT;
DLLEXPORT int get_mouse_button(int code, _Bool *is_click, _Bool *is_drag);
DLLEXPORT char *replace_termcodes(const char *const from, const size_t from_len, char **const bufp, const int flags, _Bool *const did_simplify, const int cpo_flags) FUNC_ATTR_NONNULL_ARG(1, 3);
DLLEXPORT char_u *add_char2buf(int c, char_u *s) FUNC_ATTR_NONNULL_ALL FUNC_ATTR_WARN_UNUSED_RESULT;
DLLEXPORT char *vim_strsave_escape_ks(char *p);
DLLEXPORT void vim_unescape_ks(char_u *p);
DLLEXPORT void log_key(int log_level, int key);
#include "nvim/func_attr.h"
