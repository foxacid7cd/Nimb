#define DEFINE_FUNC_ATTRIBUTES
#include "nvim/func_attr.h"
#undef DEFINE_FUNC_ATTRIBUTES
static inline void free_spat(struct spat *const spat);
static void save_incsearch_state(void);
static void restore_incsearch_state(void);
static void set_vv_searchforward(void);
static int first_submatch(regmmatch_T *rp);
static _Bool check_prevcol(char_u *linep, int col, int ch, int *prevcol);
static _Bool find_rawstring_end(char *linep, pos_T *startpos, pos_T *endpos);
static void find_mps_values(int *initc, int *findc, _Bool *backwards, _Bool switchit) FUNC_ATTR_NONNULL_ALL;
static int is_zero_width(char_u *pattern, int move, pos_T *cur, Direction direction);
static void cmdline_search_stat(int dirc, pos_T *pos, pos_T *cursor_pos, _Bool show_top_bot_msg, char_u *msgbuf, _Bool recompute, int maxcount, long timeout);
static void update_search_stat(int dirc, pos_T *pos, pos_T *cursor_pos, searchstat_T *stat, _Bool recompute, int maxcount, long timeout);
static int fuzzy_match_compute_score(const char_u *const str, const int strSz, const uint32_t *const matches, const int numMatches) FUNC_ATTR_NONNULL_ALL FUNC_ATTR_WARN_UNUSED_RESULT FUNC_ATTR_PURE;
static int fuzzy_match_recursive(const char_u *fuzpat, const char_u *str, uint32_t strIdx, int *const outScore, const char_u *const strBegin, const int strLen, const uint32_t *const srcMatches, uint32_t *const matches, const int maxMatches, int nextMatch, int *const recursionCount) FUNC_ATTR_NONNULL_ARG(1, 2, 4, 5, 8, 11) FUNC_ATTR_WARN_UNUSED_RESULT;
static int fuzzy_match_item_compare(const void *const s1, const void *const s2) FUNC_ATTR_NONNULL_ALL FUNC_ATTR_WARN_UNUSED_RESULT FUNC_ATTR_PURE;
static void fuzzy_match_in_list(list_T *const l, char_u *const str, const _Bool matchseq, const char_u *const key, Callback *const item_cb, const _Bool retmatchpos, list_T *const fmatchlist, const long max_matches) FUNC_ATTR_NONNULL_ARG(2, 5, 7);
static void do_fuzzymatch(const typval_T *const argvars, typval_T *const rettv, const _Bool retmatchpos) FUNC_ATTR_NONNULL_ALL;
static char_u *get_line_and_copy(linenr_T lnum, char_u *buf);
static void show_pat_in_path(char_u *line, int type, _Bool did_show, int action, FILE *fp, linenr_T *lnum, long count) FUNC_ATTR_NONNULL_ARG(1, 6);
#include "nvim/func_attr.h"
