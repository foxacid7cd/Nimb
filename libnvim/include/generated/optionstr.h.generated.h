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
DLLEXPORT void didset_string_options(void);
DLLEXPORT void trigger_optionsset_string(int opt_idx, int opt_flags, char *oldval, char *oldval_l, char *oldval_g, char *newval);
DLLEXPORT void check_buf_options(buf_T *buf);
DLLEXPORT void free_string_option(char *p);
DLLEXPORT void clear_string_option(char **pp);
DLLEXPORT void check_string_option(char **pp);
DLLEXPORT void set_string_option_direct(const char *name, int opt_idx, const char *val, int opt_flags, int set_sid);
DLLEXPORT void set_string_option_direct_in_win(win_T *wp, const char *name, int opt_idx, const char *val, int opt_flags, int set_sid);
DLLEXPORT char *set_string_option(const int opt_idx, const char *const value, const int opt_flags) FUNC_ATTR_NONNULL_ARG(2) FUNC_ATTR_WARN_UNUSED_RESULT;
DLLEXPORT char *check_stl_option(char *s);
DLLEXPORT char *did_set_string_option(int opt_idx, char **varp, char *oldval, char *errbuf, size_t errbuflen, int opt_flags, int *value_checked);
DLLEXPORT int check_ff_value(char *p);
#include "nvim/func_attr.h"
