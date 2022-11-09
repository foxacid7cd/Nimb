#define DEFINE_FUNC_ATTRIBUTES
#include "nvim/func_attr.h"
#undef DEFINE_FUNC_ATTRIBUTES
static int conv_error(const char *const msg, const MPConvStack *const mpstack, const char *const objname) FUNC_ATTR_NONNULL_ALL;
static inline int convert_to_json_string(garray_T *const gap, const char *const buf, const size_t len) FUNC_ATTR_NONNULL_ARG(1) FUNC_ATTR_ALWAYS_INLINE;
#include "nvim/func_attr.h"
