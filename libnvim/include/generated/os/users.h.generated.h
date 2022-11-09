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
DLLEXPORT int os_get_usernames(garray_T *users);
DLLEXPORT int os_get_username(char *s, size_t len);
DLLEXPORT int os_get_uname(uv_uid_t uid, char *s, size_t len);
DLLEXPORT char *os_get_userdir(const char *name);
DLLEXPORT char *get_users(expand_T *xp, int idx);
DLLEXPORT int match_user(char *name);
#include "nvim/func_attr.h"
