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
DLLEXPORT void set_init_tablocal(void);
DLLEXPORT void set_init_1(_Bool clean_arg);
DLLEXPORT void set_number_default(char *name, long val);
DLLEXPORT void set_init_2(_Bool headless);
DLLEXPORT void set_init_3(void);
DLLEXPORT void set_helplang_default(const char *lang);
DLLEXPORT void set_title_defaults(void);
DLLEXPORT void ex_set(exarg_T *eap);
DLLEXPORT int do_set(char *arg, int opt_flags);
DLLEXPORT void did_set_option(int opt_idx, int opt_flags, int new_value, int value_checked);
DLLEXPORT int string_to_key(char_u *arg);
DLLEXPORT void did_set_title(void);
DLLEXPORT void set_options_bin(int oldval, int newval, int opt_flags);
DLLEXPORT int get_shada_parameter(int type);
DLLEXPORT char_u *find_shada_parameter(int type);
DLLEXPORT void check_options(void);
DLLEXPORT int was_set_insecurely(win_T *const wp, char *opt, int opt_flags);
DLLEXPORT void redraw_titles(void);
DLLEXPORT _Bool valid_name(const char *val, const char *allowed) FUNC_ATTR_NONNULL_ALL FUNC_ATTR_PURE FUNC_ATTR_WARN_UNUSED_RESULT;
DLLEXPORT void check_blending(win_T *wp);
DLLEXPORT _Bool parse_winhl_opt(win_T *wp);
DLLEXPORT void set_option_sctx_idx(int opt_idx, int opt_flags, sctx_T script_ctx);
DLLEXPORT void check_redraw(uint32_t flags);
DLLEXPORT int findoption_len(const char *const arg, const size_t len);
DLLEXPORT _Bool is_tty_option(const char *name) FUNC_ATTR_NONNULL_ALL FUNC_ATTR_PURE FUNC_ATTR_WARN_UNUSED_RESULT;
DLLEXPORT _Bool get_tty_option(const char *name, char **value);
DLLEXPORT _Bool set_tty_option(const char *name, char *value);
DLLEXPORT void set_tty_background(const char *value);
DLLEXPORT int findoption(const char *const arg) FUNC_ATTR_NONNULL_ALL;
DLLEXPORT getoption_T get_option_value(const char *name, long *numval, char **stringval, uint32_t *flagsp, int scope);
DLLEXPORT int get_option_value_strict(char *name, int64_t *numval, char **stringval, int opt_type, void *from);
DLLEXPORT vimoption_T *get_option(int opt_idx);
DLLEXPORT char *set_option_value(const char *const name, const long number, const char *const string, const int opt_flags) FUNC_ATTR_NONNULL_ARG(1);
DLLEXPORT void set_option_value_give_err(const char *name, long number, const char *string, int opt_flags);
DLLEXPORT _Bool is_option_allocated(const char *name);
DLLEXPORT _Bool is_string_option(const char *name);
DLLEXPORT int find_key_option_len(const char_u *arg_arg, size_t len, _Bool has_lt);
DLLEXPORT void ui_refresh_options(void);
DLLEXPORT int makeset(FILE *fd, int opt_flags, int local_only);
DLLEXPORT int makefoldset(FILE *fd);
DLLEXPORT void unset_global_local_option(char *name, void *from);
DLLEXPORT char *get_varp_scope(vimoption_T *p, int scope);
DLLEXPORT char_u *get_equalprg(void);
DLLEXPORT void win_copy_options(win_T *wp_from, win_T *wp_to);
DLLEXPORT void copy_winopt(winopt_T *from, winopt_T *to);
DLLEXPORT void check_win_options(win_T *win);
DLLEXPORT void clear_winopt(winopt_T *wop);
DLLEXPORT void didset_window_options(win_T *wp, _Bool valid_cursor);
DLLEXPORT void buf_copy_options(buf_T *buf, int flags);
DLLEXPORT void reset_modifiable(void);
DLLEXPORT void set_iminsert_global(void);
DLLEXPORT void set_imsearch_global(void);
DLLEXPORT void set_context_in_set_cmd(expand_T *xp, char_u *arg, int opt_flags);
DLLEXPORT int ExpandSettings(expand_T *xp, regmatch_T *regmatch, int *num_file, char ***file);
DLLEXPORT void ExpandOldSetting(int *num_file, char ***file);
DLLEXPORT _Bool shortmess(int x);
DLLEXPORT void vimrc_found(char *fname, char *envname);
DLLEXPORT _Bool option_was_set(const char *name);
DLLEXPORT void reset_option_was_set(const char *name);
DLLEXPORT void fill_breakat_flags(void);
DLLEXPORT int fill_culopt_flags(char *val, win_T *wp);
DLLEXPORT int option_set_callback_func(char *optval, Callback *optcb);
DLLEXPORT _Bool can_bs(int what);
DLLEXPORT unsigned int get_bkc_value(buf_T *buf);
DLLEXPORT char *get_flp_value(buf_T *buf);
DLLEXPORT unsigned int get_ve_flags(void);
DLLEXPORT char_u *get_showbreak_value(win_T *const win) FUNC_ATTR_WARN_UNUSED_RESULT;
DLLEXPORT int get_fileformat(const buf_T *buf) FUNC_ATTR_PURE FUNC_ATTR_WARN_UNUSED_RESULT FUNC_ATTR_NONNULL_ALL;
DLLEXPORT int get_fileformat_force(const buf_T *buf, const exarg_T *eap) FUNC_ATTR_NONNULL_ARG(1);
DLLEXPORT int default_fileformat(void);
DLLEXPORT void set_fileformat(int eol_style, int opt_flags);
DLLEXPORT char *skip_to_option_part(const char *p);
DLLEXPORT size_t copy_option_part(char **option, char *buf, size_t maxlen, char *sep_chars);
DLLEXPORT int csh_like_shell(void);
DLLEXPORT _Bool fish_like_shell(void);
DLLEXPORT int win_signcol_count(win_T *wp);
DLLEXPORT int win_signcol_configured(win_T *wp, int *is_fixed);
DLLEXPORT dict_T *get_winbuf_options(const int bufopt) FUNC_ATTR_WARN_UNUSED_RESULT;
DLLEXPORT long get_scrolloff_value(win_T *wp);
DLLEXPORT long get_sidescrolloff_value(win_T *wp);
DLLEXPORT Dictionary get_vimoption(String name, Error *err);
DLLEXPORT Dictionary get_all_vimoptions(void);
#include "nvim/func_attr.h"
