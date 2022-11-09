#define DEFINE_FUNC_ATTRIBUTES
#include "nvim/func_attr.h"
#undef DEFINE_FUNC_ATTRIBUTES
static size_t line_len(const char *s);
static int matching_chars_iwhite(const char *s1, const char *s2);
static void update_path_flat(diffcmppath_T *diffcmppath, int score, size_t to, size_t from, const int choice);
static int matching_chars(const char *s1, const char *s2);
static int count_n_matched_chars(const char **sp, const size_t n, _Bool iwhite);
static void try_possible_paths(const int *df_iters, const size_t *paths, const int npaths, const int path_idx, int *choice, diffcmppath_T *diffcmppath, const int *diff_len, const size_t ndiffs, const char **diff_blk, _Bool iwhite);
static size_t unwrap_indexes(const int *values, const int *diff_len, const size_t ndiffs);
static void populate_tensor(int *df_iters, const size_t ch_dim, diffcmppath_T *diffcmppath, const int *diff_len, const size_t ndiffs, const char **diff_blk, _Bool iwhite);
#include "nvim/func_attr.h"
