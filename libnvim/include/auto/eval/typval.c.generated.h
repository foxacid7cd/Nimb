#define DEFINE_FUNC_ATTRIBUTES
#include "nvim/func_attr.h"
#undef DEFINE_FUNC_ATTRIBUTES
static listitem_T *tv_list_item_alloc(void) FUNC_ATTR_NONNULL_RET FUNC_ATTR_MALLOC;
static int list_join_inner(garray_T *const gap, list_T *const l, const char *const sep, garray_T *const join_gap) FUNC_ATTR_NONNULL_ALL;
static int item_compare(const void *s1, const void *s2, _Bool keep_zero);
static int item_compare_keeping_zero(const void *s1, const void *s2);
static int item_compare_not_keeping_zero(const void *s1, const void *s2);
static int item_compare2(const void *s1, const void *s2, _Bool keep_zero);
static int item_compare2_keeping_zero(const void *s1, const void *s2);
static int item_compare2_not_keeping_zero(const void *s1, const void *s2);
static void do_sort_uniq(typval_T *argvars, typval_T *rettv, _Bool sort);
static void tv_dict_watcher_free(DictWatcher *watcher) FUNC_ATTR_NONNULL_ALL;
static _Bool tv_dict_watcher_matches(DictWatcher *watcher, const char *const key) FUNC_ATTR_NONNULL_ALL FUNC_ATTR_WARN_UNUSED_RESULT FUNC_ATTR_PURE;
static void tv_dict_list(typval_T *const tv, typval_T *const rettv, const DictListType what);
static inline int _nothing_conv_func_start(typval_T *const tv, char_u *const fun) FUNC_ATTR_WARN_UNUSED_RESULT FUNC_ATTR_ALWAYS_INLINE FUNC_ATTR_NONNULL_ARG(1);
static inline void _nothing_conv_func_end(typval_T *const tv, const int copyID) FUNC_ATTR_ALWAYS_INLINE FUNC_ATTR_NONNULL_ALL;
static inline void _nothing_conv_empty_dict(typval_T *const tv, dict_T **const dictp) FUNC_ATTR_ALWAYS_INLINE FUNC_ATTR_NONNULL_ARG(2);
static inline int _nothing_conv_real_list_after_start(typval_T *const tv, MPConvStackVal *const mpsv) FUNC_ATTR_ALWAYS_INLINE FUNC_ATTR_WARN_UNUSED_RESULT;
static inline void _nothing_conv_list_end(typval_T *const tv) FUNC_ATTR_ALWAYS_INLINE;
static inline int _nothing_conv_real_dict_after_start(typval_T *const tv, dict_T **const dictp, const void *const nodictvar, MPConvStackVal *const mpsv) FUNC_ATTR_ALWAYS_INLINE FUNC_ATTR_WARN_UNUSED_RESULT;
static inline void _nothing_conv_dict_end(typval_T *const tv, dict_T **const dictp, const void *const nodictvar) FUNC_ATTR_ALWAYS_INLINE;
#include "nvim/func_attr.h"
