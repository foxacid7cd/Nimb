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
DLLEXPORT void syn_set_timeout(proftime_T *tm);
DLLEXPORT void syntax_start(win_T *wp, linenr_T lnum);
DLLEXPORT void syn_stack_free_all(synblock_T *block);
DLLEXPORT void syn_stack_apply_changes(buf_T *buf);
DLLEXPORT void syntax_end_parsing(win_T *wp, linenr_T lnum);
DLLEXPORT _Bool syntax_check_changed(linenr_T lnum);
DLLEXPORT int get_syntax_attr(const colnr_T col, _Bool *const can_spell, const _Bool keep_state);
DLLEXPORT void syntax_clear(synblock_T *block);
DLLEXPORT void reset_synblock(win_T *wp);
DLLEXPORT void syn_maybe_enable(void);
DLLEXPORT void ex_syntax(exarg_T *eap);
DLLEXPORT void ex_ownsyntax(exarg_T *eap);
DLLEXPORT _Bool syntax_present(win_T *win);
DLLEXPORT void reset_expand_highlight(void);
DLLEXPORT void set_context_in_echohl_cmd(expand_T *xp, const char *arg);
DLLEXPORT void set_context_in_syntax_cmd(expand_T *xp, const char *arg);
DLLEXPORT char *get_syntax_name(expand_T *xp, int idx);
DLLEXPORT int syn_get_id(win_T *wp, linenr_T lnum, colnr_T col, int trans, _Bool *spellp, int keep_state);
DLLEXPORT int get_syntax_info(int *seqnrp);
DLLEXPORT int syn_get_concealed_id(win_T *wp, linenr_T lnum, colnr_T col);
DLLEXPORT int syn_get_sub_char(void);
DLLEXPORT int syn_get_stack_item(int i);
DLLEXPORT int syn_get_foldlevel(win_T *wp, linenr_T lnum);
DLLEXPORT void ex_syntime(exarg_T *eap);
DLLEXPORT char *get_syntime_arg(expand_T *xp, int idx);
#include "nvim/func_attr.h"
