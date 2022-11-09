#define DEFINE_FUNC_ATTRIBUTES
#include "nvim/func_attr.h"
#undef DEFINE_FUNC_ATTRIBUTES
static void find_word(matchinf_T *mip, int mode);
static void find_prefix(matchinf_T *mip, int mode);
static int fold_more(matchinf_T *mip);
static void decor_spell_nav_start(win_T *wp);
static _Bool decor_spell_nav_col(win_T *wp, linenr_T lnum, linenr_T *decor_lnum, int col, char **decor_error);
static void spell_load_lang(char_u *lang);
static void int_wordlist_spl(char_u *fname);
static void free_salitem(salitem_T *smp);
static void free_fromto(fromto_T *ftp);
static void spell_load_cb(char *fname, void *cookie);
static int count_syllables(slang_T *slang, const char_u *word) FUNC_ATTR_NONNULL_ALL;
static void clear_midword(win_T *wp);
static void use_midword(slang_T *lp, win_T *wp) FUNC_ATTR_NONNULL_ALL;
static int find_region(const char_u *rp, const char_u *region);
static _Bool spell_mb_isword_class(int cl, const win_T *wp) FUNC_ATTR_PURE FUNC_ATTR_NONNULL_ALL FUNC_ATTR_WARN_UNUSED_RESULT;
static _Bool spell_iswordp_w(const int *p, const win_T *wp) FUNC_ATTR_NONNULL_ALL;
static void spell_soundfold_sofo(slang_T *slang, char_u *inword, char_u *res);
static void spell_soundfold_wsal(slang_T *slang, const char_u *inword, char_u *res);
static void dump_word(slang_T *slang, char_u *word, char_u *pat, Direction *dir, int dumpflags, int wordflags, linenr_T lnum);
static linenr_T dump_prefixes(slang_T *slang, char_u *word, char_u *pat, Direction *dir, int dumpflags, int flags, linenr_T startlnum);
#include "nvim/func_attr.h"
