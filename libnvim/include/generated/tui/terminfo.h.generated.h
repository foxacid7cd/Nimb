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
DLLEXPORT _Bool terminfo_is_term_family(const char *term, const char *family);
DLLEXPORT _Bool terminfo_is_bsd_console(const char *term);
DLLEXPORT unibi_term *terminfo_from_builtin(const char *term, char **termname);
DLLEXPORT void terminfo_info_msg(const unibi_term *const ut);
#include "nvim/func_attr.h"
