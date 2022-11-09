#define DEFINE_FUNC_ATTRIBUTES
#include "nvim/func_attr.h"
#undef DEFINE_FUNC_ATTRIBUTES
static void regcomp_start(char_u *expr, int re_flags);
static _Bool use_multibytecode(int c);
static void regc(int b);
static void regmbc(int c);
static void reg_equi_class(int c);
static char_u *regnode(int op);
static char_u *re_put_uint32(char_u *p, uint32_t val);
static char_u *regnext(char_u *p) FUNC_ATTR_NONNULL_ALL;
static void regtail(char_u *p, char_u *val);
static void regoptail(char_u *p, char_u *val);
static void reginsert(int op, char_u *opnd);
static void reginsert_nr(int op, long val, char_u *opnd);
static void reginsert_limits(int op, long minval, long maxval, char_u *opnd);
static int seen_endbrace(int refnum);
static char_u *regatom(int *flagp);
static char_u *regpiece(int *flagp);
static char_u *regconcat(int *flagp);
static char_u *regbranch(int *flagp);
static char_u *reg(int paren, int *flagp);
static regprog_T *bt_regcomp(char_u *expr, int re_flags);
static int coll_get_char(void);
static void bt_regfree(regprog_T *prog);
static void reg_save(regsave_T *save, garray_T *gap) FUNC_ATTR_NONNULL_ALL;
static void reg_restore(regsave_T *save, garray_T *gap) FUNC_ATTR_NONNULL_ALL;
static _Bool reg_save_equal(const regsave_T *save) FUNC_ATTR_NONNULL_ALL;
static void save_se_multi(save_se_T *savep, lpos_T *posp);
static void save_se_one(save_se_T *savep, char_u **pp);
static int regrepeat(char_u *p, long maxcount);
static regitem_T *regstack_push(regstate_T state, char_u *scan);
static void regstack_pop(char_u **scan);
static void save_subexpr(regbehind_T *bp) FUNC_ATTR_NONNULL_ALL;
static void restore_subexpr(regbehind_T *bp) FUNC_ATTR_NONNULL_ALL;
static _Bool regmatch(char_u *scan, proftime_T *tm, int *timed_out);
static long regtry(bt_regprog_T *prog, colnr_T col, proftime_T *tm, int *timed_out);
static long bt_regexec_both(char_u *line, colnr_T col, proftime_T *tm, int *timed_out);
static int bt_regexec_nl(regmatch_T *rmp, char_u *line, colnr_T col, _Bool line_lbr);
static long bt_regexec_multi(regmmatch_T *rmp, win_T *win, buf_T *buf, linenr_T lnum, colnr_T col, proftime_T *tm, int *timed_out);
static int re_num_cmp(uint32_t val, char_u *scan);
#include "nvim/func_attr.h"
