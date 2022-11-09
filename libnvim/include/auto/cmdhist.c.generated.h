#define DEFINE_FUNC_ATTRIBUTES
#include "nvim/func_attr.h"
#undef DEFINE_FUNC_ATTRIBUTES
static inline void hist_free_entry(histentry_T *hisptr) FUNC_ATTR_NONNULL_ALL;
static inline void clear_hist_entry(histentry_T *hisptr) FUNC_ATTR_NONNULL_ALL;
static int in_history(int type, char *str, int move_to_front, int sep);
static HistoryType get_histtype(const char *const name, const size_t len, const _Bool return_default) FUNC_ATTR_PURE FUNC_ATTR_WARN_UNUSED_RESULT;
static int get_history_idx(int histype);
static int calc_hist_idx(int histype, int num);
static char *get_history_entry(int histype, int idx);
static int del_history_entry(int histype, char_u *str);
static int del_history_idx(int histype, int idx);
#include "nvim/func_attr.h"
