#define DEFINE_FUNC_ATTRIBUTES
#include "nvim/func_attr.h"
#undef DEFINE_FUNC_ATTRIBUTES
static void vim_findfile_free_visited_list(ff_visited_list_hdr_T **list_headp);
static void ff_free_visited_list(ff_visited_T *vl);
static ff_visited_list_hdr_T *ff_get_visited_list(char *filename, ff_visited_list_hdr_T **list_headp);
static _Bool ff_wc_equal(char_u *s1, char_u *s2);
static int ff_check_visited(ff_visited_T **visited_list, char *fname, char *wc_path);
static ff_stack_T *ff_create_stack_element(char *fix_part, char *wc_part, int level, int star_star_empty);
static void ff_push(ff_search_ctx_T *search_ctx, ff_stack_T *stack_ptr);
static ff_stack_T *ff_pop(ff_search_ctx_T *search_ctx);
static void ff_free_stack_element(ff_stack_T *const stack_ptr);
static void ff_clear(ff_search_ctx_T *search_ctx);
static int ff_path_in_stoplist(char *path, int path_len, char **stopdirs_v);
#include "nvim/func_attr.h"
