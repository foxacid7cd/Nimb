#define DEFINE_FUNC_ATTRIBUTES
#include "nvim/func_attr.h"
#undef DEFINE_FUNC_ATTRIBUTES
static void prof_func_line(FILE *fd, int count, const proftime_T *total, const proftime_T *self, _Bool prefer_self);
static void prof_sort_list(FILE *fd, ufunc_T **sorttab, int st_len, char *title, _Bool prefer_self);
static int prof_total_cmp(const void *s1, const void *s2);
static int prof_self_cmp(const void *s1, const void *s2);
static void func_dump_profile(FILE *fd);
static void script_dump_profile(FILE *fd);
static void time_diff(proftime_T then, proftime_T now);
#include "nvim/func_attr.h"
