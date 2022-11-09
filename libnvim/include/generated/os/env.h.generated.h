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
DLLEXPORT void env_init(void);
DLLEXPORT void os_env_var_lock(void);
DLLEXPORT void os_env_var_unlock(void);
DLLEXPORT const char *os_getenv(const char *name) FUNC_ATTR_NONNULL_ALL;
DLLEXPORT _Bool os_env_exists(const char *name) FUNC_ATTR_NONNULL_ALL;
DLLEXPORT int os_setenv(const char *name, const char *value, int overwrite) FUNC_ATTR_NONNULL_ALL;
DLLEXPORT int os_unsetenv(const char *name) FUNC_ATTR_NONNULL_ALL;
DLLEXPORT size_t os_get_fullenv_size(void);
DLLEXPORT void os_free_fullenv(char **env);
DLLEXPORT void os_copy_fullenv(char **env, size_t env_size);
DLLEXPORT char *os_getenvname_at_index(size_t index);
DLLEXPORT int64_t os_get_pid(void);
DLLEXPORT void os_get_hostname(char *hostname, size_t size);
DLLEXPORT void init_homedir(void);
DLLEXPORT char *expand_env_save(char *src);
DLLEXPORT char_u *expand_env_save_opt(char_u *src, _Bool one);
DLLEXPORT void expand_env(char *src, char *dst, int dstlen);
DLLEXPORT void expand_env_esc(char_u *restrict srcp, char_u *restrict dst, int dstlen, _Bool esc, _Bool one, char_u *prefix) FUNC_ATTR_NONNULL_ARG(1, 2);
DLLEXPORT const void *vim_env_iter(const char delim, const char *const val, const void *const iter, const char **const dir, size_t *const len) FUNC_ATTR_NONNULL_ARG(2, 4, 5) FUNC_ATTR_WARN_UNUSED_RESULT;
DLLEXPORT const void *vim_env_iter_rev(const char delim, const char *const val, const void *const iter, const char **const dir, size_t *const len) FUNC_ATTR_NONNULL_ARG(2, 4, 5) FUNC_ATTR_WARN_UNUSED_RESULT;
DLLEXPORT void vim_get_prefix_from_exepath(char *exe_name);
DLLEXPORT char *vim_getenv(const char *name);
DLLEXPORT size_t home_replace(const buf_T *const buf, const char *src, char *const dst, size_t dstlen, const _Bool one) FUNC_ATTR_NONNULL_ARG(3);
DLLEXPORT char *home_replace_save(buf_T *buf, const char *src) FUNC_ATTR_NONNULL_RET;
DLLEXPORT char *get_env_name(expand_T *xp, int idx);
DLLEXPORT _Bool os_setenv_append_path(const char *fname) FUNC_ATTR_NONNULL_ALL;
DLLEXPORT _Bool os_shell_is_cmdexe(const char *sh) FUNC_ATTR_NONNULL_ALL;
DLLEXPORT void vim_unsetenv_ext(const char *var);
DLLEXPORT void vim_setenv_ext(const char *name, const char *val);
#include "nvim/func_attr.h"
