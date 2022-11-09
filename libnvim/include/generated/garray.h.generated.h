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
DLLEXPORT void ga_clear(garray_T *gap);
DLLEXPORT void ga_clear_strings(garray_T *gap);
DLLEXPORT void ga_init(garray_T *gap, int itemsize, int growsize);
DLLEXPORT void ga_set_growsize(garray_T *gap, int growsize);
DLLEXPORT void ga_grow(garray_T *gap, int n);
DLLEXPORT void ga_remove_duplicate_strings(garray_T *gap);
DLLEXPORT char *ga_concat_strings_sep(const garray_T *gap, const char *sep) FUNC_ATTR_NONNULL_RET;
DLLEXPORT char_u *ga_concat_strings(const garray_T *gap) FUNC_ATTR_NONNULL_RET;
DLLEXPORT void ga_concat(garray_T *gap, const char *restrict s);
DLLEXPORT void ga_concat_len(garray_T *const gap, const char *restrict s, const size_t len) FUNC_ATTR_NONNULL_ALL;
DLLEXPORT void ga_append(garray_T *gap, char c);
#include "nvim/func_attr.h"
