#define DEFINE_FUNC_ATTRIBUTES
#include "nvim/func_attr.h"
#undef DEFINE_FUNC_ATTRIBUTES
static int sort_compare(const void *s1, const void *s2) FUNC_ATTR_NONNULL_ALL;
static varnumber_T tv_nr(typval_T *tvs, int *idxp) FUNC_ATTR_NONNULL_ALL FUNC_ATTR_WARN_UNUSED_RESULT;
static const char *tv_str(typval_T *tvs, int *idxp, char **const tofree) FUNC_ATTR_NONNULL_ALL FUNC_ATTR_WARN_UNUSED_RESULT;
static const void *tv_ptr(const typval_T *const tvs, int *const idxp) FUNC_ATTR_NONNULL_ALL FUNC_ATTR_WARN_UNUSED_RESULT;
static float_T tv_float(typval_T *const tvs, int *const idxp) FUNC_ATTR_NONNULL_ALL FUNC_ATTR_WARN_UNUSED_RESULT;
static const char *infinity_str(_Bool positive, char fmt_spec, int force_sign, int space_for_positive);
#include "nvim/func_attr.h"
