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
DLLEXPORT void do_ascii(const exarg_T *const eap);
DLLEXPORT void ex_align(exarg_T *eap);
DLLEXPORT void ex_sort(exarg_T *eap);
DLLEXPORT void ex_retab(exarg_T *eap);
DLLEXPORT int do_move(linenr_T line1, linenr_T line2, linenr_T dest);
DLLEXPORT void ex_copy(linenr_T line1, linenr_T line2, linenr_T n);
DLLEXPORT void do_bang(int addr_count, exarg_T *eap, _Bool forceit, _Bool do_in, _Bool do_out) FUNC_ATTR_NONNULL_ALL;
DLLEXPORT void do_shell(char *cmd, int flags);
DLLEXPORT char *make_filter_cmd(char *cmd, char *itmp, char *otmp);
DLLEXPORT void append_redir(char *const buf, const size_t buflen, const char *const opt, const char *const fname);
DLLEXPORT void print_line_no_prefix(linenr_T lnum, int use_number, int list);
DLLEXPORT void print_line(linenr_T lnum, int use_number, int list);
DLLEXPORT int rename_buffer(char *new_fname);
DLLEXPORT void ex_file(exarg_T *eap);
DLLEXPORT void ex_update(exarg_T *eap);
DLLEXPORT void ex_write(exarg_T *eap);
DLLEXPORT int do_write(exarg_T *eap);
DLLEXPORT int check_overwrite(exarg_T *eap, buf_T *buf, char *fname, char *ffname, int other);
DLLEXPORT void ex_wnext(exarg_T *eap);
DLLEXPORT void do_wqall(exarg_T *eap);
DLLEXPORT _Bool not_writing(void);
DLLEXPORT int getfile(int fnum, char *ffname_arg, char *sfname_arg, int setpm, linenr_T lnum, int forceit);
DLLEXPORT int do_ecmd(int fnum, char *ffname, char *sfname, exarg_T *eap, linenr_T newlnum, int flags, win_T *oldwin);
DLLEXPORT void ex_append(exarg_T *eap);
DLLEXPORT void ex_change(exarg_T *eap);
DLLEXPORT void ex_z(exarg_T *eap);
DLLEXPORT _Bool check_secure(void);
DLLEXPORT void sub_get_replacement(SubReplacementString *const ret_sub) FUNC_ATTR_NONNULL_ALL;
DLLEXPORT void sub_set_replacement(SubReplacementString sub);
DLLEXPORT _Bool do_sub_msg(_Bool count_only);
DLLEXPORT void ex_global(exarg_T *eap);
DLLEXPORT void global_exe(char *cmd);
DLLEXPORT _Bool prepare_tagpreview(_Bool undo_sync);
DLLEXPORT void ex_substitute(exarg_T *eap);
DLLEXPORT int ex_substitute_preview(exarg_T *eap, long cmdpreview_ns, handle_T cmdpreview_bufnr);
DLLEXPORT char *skip_vimgrep_pat(char *p, char **s, int *flags);
DLLEXPORT void ex_oldfiles(exarg_T *eap);
#include "nvim/func_attr.h"
