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
DLLEXPORT handle_T cmdpreview_get_bufnr(void);
DLLEXPORT long cmdpreview_get_ns(void);
DLLEXPORT char_u *getcmdline(int firstc, long count, int indent, _Bool do_concat FUNC_ATTR_UNUSED);
DLLEXPORT char *getcmdline_prompt(const int firstc, const char *const prompt, const int attr, const int xp_context, const char *const xp_arg, const Callback highlight_callback) FUNC_ATTR_WARN_UNUSED_RESULT FUNC_ATTR_MALLOC;
DLLEXPORT char_u *get_cmdprompt(void);
DLLEXPORT int check_opt_wim(void);
DLLEXPORT _Bool text_locked(void);
DLLEXPORT void text_locked_msg(void);
DLLEXPORT char *get_text_locked_msg(void);
DLLEXPORT _Bool text_or_buf_locked(void);
DLLEXPORT _Bool curbuf_locked(void);
DLLEXPORT _Bool allbuf_locked(void);
DLLEXPORT int cmd_screencol(int bytepos);
DLLEXPORT char *getexline(int c, void *cookie, int indent, _Bool do_concat);
DLLEXPORT _Bool cmdline_overstrike(void) FUNC_ATTR_PURE;
DLLEXPORT _Bool cmdline_at_end(void) FUNC_ATTR_PURE;
DLLEXPORT void realloc_cmdbuff(int len);
DLLEXPORT void ui_ext_cmdline_block_append(size_t indent, const char *line);
DLLEXPORT void ui_ext_cmdline_block_leave(void);
DLLEXPORT void cmdline_screen_cleared(void);
DLLEXPORT void cmdline_ui_flush(void);
DLLEXPORT void putcmdline(char c, int shift);
DLLEXPORT void unputcmdline(void);
DLLEXPORT void put_on_cmdline(char_u *str, int len, int redraw);
DLLEXPORT void cmdline_paste_str(char_u *s, int literally);
DLLEXPORT void redrawcmdline(void);
DLLEXPORT void redrawcmd(void);
DLLEXPORT void compute_cmdrow(void);
DLLEXPORT void cursorcmd(void);
DLLEXPORT void gotocmdline(_Bool clr);
DLLEXPORT char *vim_strsave_fnameescape(const char *const fname, const int what) FUNC_ATTR_NONNULL_RET FUNC_ATTR_MALLOC FUNC_ATTR_NONNULL_ALL;
DLLEXPORT void escape_fname(char **pp);
DLLEXPORT void tilde_replace(char_u *orig_pat, int num_files, char **files);
DLLEXPORT CmdlineInfo *get_cmdline_info(void);
DLLEXPORT unsigned get_cmdline_last_prompt_id(void);
DLLEXPORT void f_getcmdcompltype(typval_T *argvars, typval_T *rettv, EvalFuncData fptr);
DLLEXPORT void f_getcmdline(typval_T *argvars, typval_T *rettv, EvalFuncData fptr);
DLLEXPORT void f_getcmdpos(typval_T *argvars, typval_T *rettv, EvalFuncData fptr);
DLLEXPORT void f_getcmdscreenpos(typval_T *argvars, typval_T *rettv, EvalFuncData fptr);
DLLEXPORT void f_getcmdtype(typval_T *argvars, typval_T *rettv, EvalFuncData fptr);
DLLEXPORT void f_setcmdline(typval_T *argvars, typval_T *rettv, EvalFuncData fptr);
DLLEXPORT void f_setcmdpos(typval_T *argvars, typval_T *rettv, EvalFuncData fptr);
DLLEXPORT int get_cmdline_firstc(void);
DLLEXPORT int get_list_range(char **str, int *num1, int *num2);
DLLEXPORT void cmdline_init(void);
DLLEXPORT char *check_cedit(void);
DLLEXPORT _Bool is_in_cmdwin(void) FUNC_ATTR_PURE FUNC_ATTR_WARN_UNUSED_RESULT;
DLLEXPORT char *script_get(exarg_T *const eap, size_t *const lenp) FUNC_ATTR_NONNULL_ALL FUNC_ATTR_WARN_UNUSED_RESULT FUNC_ATTR_MALLOC;
#include "nvim/func_attr.h"
