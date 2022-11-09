#define DEFINE_FUNC_ATTRIBUTES
#include "nvim/func_attr.h"
#undef DEFINE_FUNC_ATTRIBUTES
static void diff_buf_clear(void);
static int diff_buf_idx(buf_T *buf);
static int diff_buf_idx_tp(buf_T *buf, tabpage_T *tp);
static void diff_mark_adjust_tp(tabpage_T *tp, int idx, linenr_T line1, linenr_T line2, linenr_T amount, linenr_T amount_after);
static diff_T *diff_alloc_new(tabpage_T *tp, diff_T *dprev, diff_T *dp);
static diff_T *diff_free(tabpage_T *tp, diff_T *dprev, diff_T *dp);
static void diff_check_unchanged(tabpage_T *tp, diff_T *dp);
static int diff_check_sanity(tabpage_T *tp, diff_T *dp);
static void clear_diffin(diffin_T *din);
static void clear_diffout(diffout_T *dout);
static int diff_write_buffer(buf_T *buf, mmfile_t *m, linenr_T start, linenr_T end);
static int diff_write(buf_T *buf, diffin_T *din);
static void diff_try_update(diffio_T *dio, int idx_orig, exarg_T *eap);
static int diff_internal_failed(void);
static int check_external_diff(diffio_T *diffio);
static int diff_file_internal(diffio_T *diffio);
static int diff_file(diffio_T *dio);
static void set_diff_option(win_T *wp, int value);
static _Bool extract_hunk_internal(diffout_T *dout, diffhunk_T *hunk, int *line_idx);
static _Bool extract_hunk(FILE *fd, diffhunk_T *hunk, diffstyle_T *diffstyle);
static void process_hunk(diff_T **dpp, diff_T **dprevp, int idx_orig, int idx_new, diffhunk_T *hunk, _Bool *notsetp);
static void diff_read(int idx_orig, int idx_new, diffio_T *dio);
static void diff_copy_entry(diff_T *dprev, diff_T *dp, int idx_orig, int idx_new);
static int get_max_diff_length(const diff_T *dp);
static void find_top_diff_block(diff_T **thistopdiff, diff_T **nextblockblock, int fromidx, int topline);
static void count_filler_lines_and_topline(int *curlinenum_to, int *linesfiller, const diff_T *thistopdiff, const int toidx, int virtual_lines_passed);
static void calculate_topfill_and_topline(const int fromidx, const int toidx, const int from_topline, const int from_topfill, int *topfill, linenr_T *topline);
static int linematched_filler_lines(diff_T *dp, int idx, linenr_T lnum, int *linestatus);
static void apply_linematch_results(diff_T *dp, size_t decisions_length, const int *decisions);
static void run_linematch_algorithm(diff_T *dp);
static _Bool diff_equal_entry(diff_T *dp, int idx1, int idx2) FUNC_ATTR_PURE FUNC_ATTR_WARN_UNUSED_RESULT FUNC_ATTR_NONNULL_ARG(1);
static _Bool diff_equal_char(const char *const p1, const char *const p2, int *const len);
static int diff_cmp(char *s1, char *s2);
static _Bool valid_diff(diff_T *diff);
static void diffgetput(const int addr_count, const int idx_cur, const int idx_from, const int idx_to, const linenr_T line1, const linenr_T line2);
static void diff_fold_update(diff_T *dp, int skip_idx);
static linenr_T diff_get_corresponding_line_int(buf_T *buf1, linenr_T lnum1);
static int parse_diff_ed(char *line, diffhunk_T *hunk);
static int parse_diff_unified(char *line, diffhunk_T *hunk);
static int xdiff_out(long start_a, long count_a, long start_b, long count_b, void *priv);
#include "nvim/func_attr.h"
