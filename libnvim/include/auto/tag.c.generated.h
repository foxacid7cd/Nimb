#define DEFINE_FUNC_ATTRIBUTES
#include "nvim/func_attr.h"
#undef DEFINE_FUNC_ATTRIBUTES
static void print_tag_list(int new_tag, int use_tagstack, int num_matches, char **matches);
static int add_llist_tags(char_u *tag, int num_matches, char **matches);
static void taglen_advance(int l);
static int tag_strnicmp(char_u *s1, char_u *s2, size_t len);
static void prepare_pats(pat_T *pats, int has_re);
static int find_tagfunc_tags(char_u *pat, garray_T *ga, int *match_count, int flags, char_u *buf_ffname);
static void found_tagfile_cb(char *fname, void *cookie);
static int parse_tag_line(char_u *lbuf, tagptrs_T *tagp);
static _Bool test_for_static(tagptrs_T *tagp);
static size_t matching_line_len(const char *const lbuf);
static int parse_match(char *lbuf, tagptrs_T *tagp);
static char_u *tag_full_fname(tagptrs_T *tagp);
static int jumpto_tag(const char_u *lbuf_arg, int forceit, int keep_help);
static char *expand_tag_fname(char *fname, char *const tag_fname, const _Bool expand);
static int test_for_current(char *fname, char *fname_end, char *tag_fname, char *buf_ffname);
static int find_extra(char_u **pp);
static void tagstack_clear_entry(taggy_T *item);
static int add_tag_field(dict_T *dict, const char *field_name, const char *start, const char *end) FUNC_ATTR_NONNULL_ARG(1, 2);
static void get_tag_details(taggy_T *tag, dict_T *retdict);
static void tagstack_clear(win_T *wp);
static void tagstack_shift(win_T *wp);
static void tagstack_push_item(win_T *wp, char *tagname, int cur_fnum, int cur_match, pos_T mark, int fnum, char *user_data);
static void tagstack_push_items(win_T *wp, list_T *l);
static void tagstack_set_curidx(win_T *wp, int curidx);
#include "nvim/func_attr.h"
