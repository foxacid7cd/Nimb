#define DEFINE_FUNC_ATTRIBUTES
#include "nvim/func_attr.h"
#undef DEFINE_FUNC_ATTRIBUTES
#ifndef DLLEXPORT
#  ifdef MSWIN
#    define DLLEXPORT __declspec(dllexport)
#  else
#    define DLLEXPORT
#  endif
#endif
DLLEXPORT size_t spell_check(win_T *wp, char_u *ptr, hlf_T *attrp, int *capcol, _Bool docount);
DLLEXPORT _Bool match_checkcompoundpattern(char_u *ptr, int wlen, garray_T *gap);
DLLEXPORT _Bool can_compound(slang_T *slang, const char_u *word, const char_u *flags) FUNC_ATTR_NONNULL_ALL;
DLLEXPORT _Bool match_compoundrule(slang_T *slang, const char_u *compflags);
DLLEXPORT int valid_word_prefix(int totprefcnt, int arridx, int flags, char_u *word, slang_T *slang, _Bool cond_req);
DLLEXPORT _Bool spell_valid_case(int wordflags, int treeflags);
DLLEXPORT _Bool no_spell_checking(win_T *wp);
DLLEXPORT size_t spell_move_to(win_T *wp, int dir, _Bool allwords, _Bool curline, hlf_T *attrp);
DLLEXPORT void spell_cat_line(char_u *buf, char_u *line, int maxlen);
DLLEXPORT char_u *spell_enc(void);
DLLEXPORT slang_T *slang_alloc(char *lang) FUNC_ATTR_NONNULL_RET;
DLLEXPORT void slang_free(slang_T *lp);
DLLEXPORT void slang_clear(slang_T *lp);
DLLEXPORT void slang_clear_sug(slang_T *lp);
DLLEXPORT void count_common_word(slang_T *lp, char *word, int len, uint8_t count);
DLLEXPORT _Bool byte_in_str(char_u *str, int n);
DLLEXPORT int init_syl_tab(slang_T *slang);
DLLEXPORT char *did_set_spelllang(win_T *wp);
DLLEXPORT int captype(char_u *word, const char_u *end) FUNC_ATTR_NONNULL_ARG(1);
DLLEXPORT void spell_delete_wordlist(void);
DLLEXPORT void spell_free_all(void);
DLLEXPORT void spell_reload(void);
DLLEXPORT buf_T *open_spellbuf(void);
DLLEXPORT void close_spellbuf(buf_T *buf);
DLLEXPORT void clear_spell_chartab(spelltab_T *sp);
DLLEXPORT void init_spell_chartab(void);
DLLEXPORT _Bool spell_iswordp(const char_u *p, const win_T *wp) FUNC_ATTR_NONNULL_ALL;
DLLEXPORT _Bool spell_iswordp_nmw(const char_u *p, win_T *wp);
DLLEXPORT int spell_casefold(const win_T *wp, char_u *str, int len, char_u *buf, int buflen) FUNC_ATTR_NONNULL_ALL;
DLLEXPORT _Bool check_need_cap(linenr_T lnum, colnr_T col);
DLLEXPORT void ex_spellrepall(exarg_T *eap);
DLLEXPORT void onecap_copy(char_u *word, char_u *wcopy, _Bool upper);
DLLEXPORT void allcap_copy(char_u *word, char_u *wcopy);
DLLEXPORT int nofold_len(char_u *fword, int flen, char_u *word);
DLLEXPORT void make_case_word(char_u *fword, char_u *cword, int flags);
DLLEXPORT char *eval_soundfold(const char *const word) FUNC_ATTR_WARN_UNUSED_RESULT FUNC_ATTR_MALLOC FUNC_ATTR_NONNULL_ALL;
DLLEXPORT void spell_soundfold(slang_T *slang, char_u *inword, _Bool folded, char_u *res);
DLLEXPORT void ex_spellinfo(exarg_T *eap);
DLLEXPORT void ex_spelldump(exarg_T *eap);
DLLEXPORT void spell_dump_compl(char *pat, int ic, Direction *dir, int dumpflags_arg);
DLLEXPORT char_u *spell_to_word_end(char_u *start, win_T *win);
DLLEXPORT int spell_word_start(int startcol);
DLLEXPORT void spell_expand_check_cap(colnr_T col);
DLLEXPORT int expand_spelling(linenr_T lnum, char_u *pat, char ***matchp);
DLLEXPORT _Bool valid_spelllang(const char *val) FUNC_ATTR_NONNULL_ALL FUNC_ATTR_PURE FUNC_ATTR_WARN_UNUSED_RESULT;
DLLEXPORT _Bool valid_spellfile(const char *val) FUNC_ATTR_NONNULL_ALL FUNC_ATTR_PURE FUNC_ATTR_WARN_UNUSED_RESULT;
DLLEXPORT char *did_set_spell_option(_Bool is_spellfile);
DLLEXPORT char *compile_cap_prog(synblock_T *synblock) FUNC_ATTR_NONNULL_ALL;
#include "nvim/func_attr.h"
