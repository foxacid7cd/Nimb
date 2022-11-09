#define DEFINE_FUNC_ATTRIBUTES
#include "nvim/func_attr.h"
#undef DEFINE_FUNC_ATTRIBUTES
static inline char *do_concat_fnames(char *fname1, const size_t len1, const char *fname2, const size_t len2, const _Bool sep) FUNC_ATTR_NONNULL_ALL FUNC_ATTR_NONNULL_RET;
static int pstrcmp(const void *a, const void *b);
static size_t path_expand(garray_T *gap, const char_u *path, int flags) FUNC_ATTR_NONNULL_ALL;
static const char *scandir_next_with_dots(Directory *dir);
static size_t do_path_expand(garray_T *gap, const char *path, size_t wildoff, int flags, _Bool didstar) FUNC_ATTR_NONNULL_ALL;
static int find_previous_pathsep(char_u *path, char_u **psep);
static _Bool is_unique(char *maybe_unique, garray_T *gap, int i);
static void expand_path_option(char_u *curdir, garray_T *gap);
static char_u *get_path_cutoff(char_u *fname, garray_T *gap);
static void uniquefy_paths(garray_T *gap, char_u *pattern);
static int expand_in_path(garray_T *const gap, char_u *const pattern, const int flags);
static _Bool has_env_var(char_u *p);
static _Bool has_special_wildchar(char_u *p);
static int vim_backtick(char_u *p);
static int expand_backtick(garray_T *gap, char *pat, int flags);
static char *eval_includeexpr(const char *const ptr, const size_t len);
static int path_to_absolute(const char *fname, char *buf, size_t len, int force);
#include "nvim/func_attr.h"
