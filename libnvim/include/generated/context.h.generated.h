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
DLLEXPORT void ctx_free_all(void);
DLLEXPORT size_t ctx_size(void) FUNC_ATTR_PURE;
DLLEXPORT Context *ctx_get(size_t index) FUNC_ATTR_PURE;
DLLEXPORT void ctx_free(Context *ctx) FUNC_ATTR_NONNULL_ALL;
DLLEXPORT void ctx_save(Context *ctx, const int flags);
DLLEXPORT _Bool ctx_restore(Context *ctx, const int flags);
DLLEXPORT Dictionary ctx_to_dict(Context *ctx) FUNC_ATTR_NONNULL_ALL;
DLLEXPORT int ctx_from_dict(Dictionary dict, Context *ctx) FUNC_ATTR_NONNULL_ALL;
#include "nvim/func_attr.h"
