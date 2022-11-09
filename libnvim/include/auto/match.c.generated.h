#define DEFINE_FUNC_ATTRIBUTES
#include "nvim/func_attr.h"
#undef DEFINE_FUNC_ATTRIBUTES
static int match_add(win_T *wp, const char *const grp, const char *const pat, int prio, int id, list_T *pos_list, const char *const conceal_char) FUNC_ATTR_NONNULL_ARG(1, 2);
static int match_delete(win_T *wp, int id, _Bool perr);
static matchitem_T *get_match(win_T *wp, int id);
static int next_search_hl_pos(match_T *shl, linenr_T lnum, matchitem_T *match, colnr_T mincol) FUNC_ATTR_NONNULL_ALL;
static void next_search_hl(win_T *win, match_T *search_hl, match_T *shl, linenr_T lnum, colnr_T mincol, matchitem_T *cur) FUNC_ATTR_NONNULL_ARG(2);
static void check_cur_search_hl(win_T *wp, match_T *shl);
static int matchadd_dict_arg(typval_T *tv, const char **conceal_char, win_T **win);
#include "nvim/func_attr.h"
