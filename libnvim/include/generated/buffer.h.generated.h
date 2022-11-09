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
DLLEXPORT int get_highest_fnum(void);
DLLEXPORT int open_buffer(int read_stdin, exarg_T *eap, int flags_arg);
DLLEXPORT void set_bufref(bufref_T *bufref, buf_T *buf);
DLLEXPORT _Bool bufref_valid(bufref_T *bufref) FUNC_ATTR_PURE;
DLLEXPORT _Bool buf_valid(buf_T *buf) FUNC_ATTR_PURE FUNC_ATTR_WARN_UNUSED_RESULT;
DLLEXPORT _Bool close_buffer(win_T *win, buf_T *buf, int action, _Bool abort_if_last, _Bool ignore_abort);
DLLEXPORT void buf_clear_file(buf_T *buf);
DLLEXPORT void buf_clear(void);
DLLEXPORT void buf_freeall(buf_T *buf, int flags);
DLLEXPORT void goto_buffer(exarg_T *eap, int start, int dir, int count);
DLLEXPORT void handle_swap_exists(bufref_T *old_curbuf);
DLLEXPORT char *do_bufdel(int command, char *arg, int addr_count, int start_bnr, int end_bnr, int forceit);
DLLEXPORT int do_buffer(int action, int start, int dir, int count, int forceit);
DLLEXPORT void set_curbuf(buf_T *buf, int action);
DLLEXPORT void enter_buffer(buf_T *buf);
DLLEXPORT void do_autochdir(void);
DLLEXPORT void no_write_message(void);
DLLEXPORT void no_write_message_nobang(const buf_T *const buf) FUNC_ATTR_NONNULL_ALL;
DLLEXPORT buf_T *buflist_new(char *ffname_arg, char *sfname_arg, linenr_T lnum, int flags);
DLLEXPORT _Bool curbuf_reusable(void);
DLLEXPORT void free_buf_options(buf_T *buf, int free_p_ff);
DLLEXPORT int buflist_getfile(int n, linenr_T lnum, int options, int forceit);
DLLEXPORT void buflist_getfpos(void);
DLLEXPORT buf_T *buflist_findname_exp(char *fname);
DLLEXPORT buf_T *buflist_findname(char *ffname);
DLLEXPORT int buflist_findpat(const char *pattern, const char *pattern_end, _Bool unlisted, _Bool diffmode, _Bool curtab_only) FUNC_ATTR_NONNULL_ARG(1);
DLLEXPORT int ExpandBufnames(char *pat, int *num_file, char ***file, int options);
DLLEXPORT buf_T *buflist_findnr(int nr);
DLLEXPORT char *buflist_nr2name(int n, int fullname, int helptail);
DLLEXPORT void buflist_setfpos(buf_T *const buf, win_T *const win, linenr_T lnum, colnr_T col, _Bool copy_options) FUNC_ATTR_NONNULL_ARG(1);
DLLEXPORT void get_winopts(buf_T *buf);
DLLEXPORT fmark_T *buflist_findfmark(buf_T *buf) FUNC_ATTR_PURE;
DLLEXPORT linenr_T buflist_findlnum(buf_T *buf) FUNC_ATTR_PURE;
DLLEXPORT void buflist_list(exarg_T *eap);
DLLEXPORT int buflist_name_nr(int fnum, char **fname, linenr_T *lnum);
DLLEXPORT int setfname(buf_T *buf, char *ffname_arg, char *sfname_arg, _Bool message);
DLLEXPORT void buf_set_name(int fnum, char *name);
DLLEXPORT void buf_name_changed(buf_T *buf);
DLLEXPORT buf_T *setaltfname(char *ffname, char *sfname, linenr_T lnum);
DLLEXPORT char *getaltfname(_Bool errmsg);
DLLEXPORT int buflist_add(char *fname, int flags);
DLLEXPORT void buflist_altfpos(win_T *win);
DLLEXPORT _Bool otherfile(char *ffname) FUNC_ATTR_PURE FUNC_ATTR_WARN_UNUSED_RESULT FUNC_ATTR_NONNULL_ALL;
DLLEXPORT void buf_set_file_id(buf_T *buf);
DLLEXPORT void fileinfo(int fullname, int shorthelp, int dont_truncate);
DLLEXPORT void col_print(char *buf, size_t buflen, int col, int vcol);
DLLEXPORT void maketitle(void);
DLLEXPORT void resettitle(void);
DLLEXPORT void get_rel_pos(win_T *wp, char *buf, int buflen);
DLLEXPORT _Bool append_arg_number(win_T *wp, char *buf, int buflen, _Bool add_file) FUNC_ATTR_NONNULL_ALL;
DLLEXPORT void fname_expand(buf_T *buf, char **ffname, char **sfname);
DLLEXPORT _Bool bt_prompt(buf_T *buf) FUNC_ATTR_PURE;
DLLEXPORT void ex_buffer_all(exarg_T *eap);
DLLEXPORT void do_modelines(int flags);
DLLEXPORT _Bool bt_help(const buf_T *const buf) FUNC_ATTR_PURE FUNC_ATTR_WARN_UNUSED_RESULT;
DLLEXPORT _Bool bt_normal(const buf_T *const buf) FUNC_ATTR_PURE FUNC_ATTR_WARN_UNUSED_RESULT;
DLLEXPORT _Bool bt_quickfix(const buf_T *const buf) FUNC_ATTR_PURE FUNC_ATTR_WARN_UNUSED_RESULT;
DLLEXPORT _Bool bt_terminal(const buf_T *const buf) FUNC_ATTR_PURE FUNC_ATTR_WARN_UNUSED_RESULT;
DLLEXPORT _Bool bt_nofilename(const buf_T *const buf) FUNC_ATTR_PURE FUNC_ATTR_WARN_UNUSED_RESULT;
DLLEXPORT _Bool bt_nofile(const buf_T *const buf) FUNC_ATTR_PURE FUNC_ATTR_WARN_UNUSED_RESULT;
DLLEXPORT _Bool bt_dontwrite(const buf_T *const buf) FUNC_ATTR_PURE FUNC_ATTR_WARN_UNUSED_RESULT;
DLLEXPORT _Bool bt_dontwrite_msg(const buf_T *const buf) FUNC_ATTR_PURE FUNC_ATTR_WARN_UNUSED_RESULT;
DLLEXPORT _Bool buf_hide(const buf_T *const buf) FUNC_ATTR_PURE;
DLLEXPORT char *buf_spname(buf_T *buf);
DLLEXPORT _Bool find_win_for_buf(buf_T *buf, win_T **wp, tabpage_T **tp);
DLLEXPORT void buf_signcols_del_check(buf_T *buf, linenr_T line1, linenr_T line2);
DLLEXPORT void buf_signcols_add_check(buf_T *buf, sign_entry_T *added);
DLLEXPORT int buf_signcols(buf_T *buf, int maximum);
DLLEXPORT char *buf_get_fname(const buf_T *buf) FUNC_ATTR_PURE FUNC_ATTR_WARN_UNUSED_RESULT FUNC_ATTR_NONNULL_ALL;
DLLEXPORT void set_buflisted(int on);
DLLEXPORT _Bool buf_contents_changed(buf_T *buf) FUNC_ATTR_NONNULL_ALL;
DLLEXPORT void wipe_buffer(buf_T *buf, _Bool aucmd);
DLLEXPORT int buf_open_scratch(handle_T bufnr, char *bufname);
#include "nvim/func_attr.h"
