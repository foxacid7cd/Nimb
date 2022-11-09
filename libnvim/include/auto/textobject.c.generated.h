#define DEFINE_FUNC_ATTRIBUTES
#include "nvim/func_attr.h"
#undef DEFINE_FUNC_ATTRIBUTES
static _Bool inmacro(char_u *opt, const char_u *s);
static int cls(void);
static _Bool skip_chars(int cclass, int dir);
static void back_in_line(void);
static void find_first_blank(pos_T *posp);
static void findsent_forward(long count, _Bool at_start_sent);
static _Bool in_html_tag(_Bool end_tag);
static int find_next_quote(char_u *line, int col, int quotechar, char_u *escape);
static int find_prev_quote(char_u *line, int col_start, int quotechar, char_u *escape);
#include "nvim/func_attr.h"
