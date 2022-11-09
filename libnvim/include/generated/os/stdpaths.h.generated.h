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
DLLEXPORT char *stdpaths_get_xdg_var(const XDGVarType idx) FUNC_ATTR_WARN_UNUSED_RESULT;
DLLEXPORT char *get_xdg_home(const XDGVarType idx) FUNC_ATTR_WARN_UNUSED_RESULT;
DLLEXPORT char *stdpaths_user_cache_subpath(const char *fname) FUNC_ATTR_WARN_UNUSED_RESULT FUNC_ATTR_NONNULL_ALL FUNC_ATTR_NONNULL_RET;
DLLEXPORT char *stdpaths_user_conf_subpath(const char *fname) FUNC_ATTR_WARN_UNUSED_RESULT FUNC_ATTR_NONNULL_ALL FUNC_ATTR_NONNULL_RET;
DLLEXPORT char *stdpaths_user_data_subpath(const char *fname) FUNC_ATTR_WARN_UNUSED_RESULT FUNC_ATTR_NONNULL_ALL FUNC_ATTR_NONNULL_RET;
DLLEXPORT char *stdpaths_user_state_subpath(const char *fname, const size_t trailing_pathseps, const _Bool escape_commas) FUNC_ATTR_WARN_UNUSED_RESULT FUNC_ATTR_NONNULL_ALL FUNC_ATTR_NONNULL_RET;
#include "nvim/func_attr.h"
