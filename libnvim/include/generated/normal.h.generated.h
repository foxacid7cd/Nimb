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
DLLEXPORT void init_normal_cmds(void);
DLLEXPORT void normal_enter(_Bool cmdwin, _Bool noexmode);
DLLEXPORT void end_visual_mode(void);
DLLEXPORT void reset_VIsual_and_resel(void);
DLLEXPORT void reset_VIsual(void);
DLLEXPORT void restore_visual_mode(void);
DLLEXPORT size_t find_ident_under_cursor(char **text, int find_type) FUNC_ATTR_NONNULL_ARG(1);
DLLEXPORT size_t find_ident_at_pos(win_T *wp, linenr_T lnum, colnr_T startcol, char **text, int *textcol, int find_type) FUNC_ATTR_NONNULL_ARG(1, 4);
DLLEXPORT void prep_redo(int regname, long num, int cmd1, int cmd2, int cmd3, int cmd4, int cmd5);
DLLEXPORT void prep_redo_num2(int regname, long num1, int cmd1, int cmd2, long num2, int cmd3, int cmd4, int cmd5);
DLLEXPORT void clearop(oparg_T *oap);
DLLEXPORT void clearopbeep(oparg_T *oap);
DLLEXPORT void may_clear_cmdline(void);
DLLEXPORT void clear_showcmd(void);
DLLEXPORT _Bool add_to_showcmd(int c);
DLLEXPORT void add_to_showcmd_c(int c);
DLLEXPORT void push_showcmd(void);
DLLEXPORT void pop_showcmd(void);
DLLEXPORT void do_check_scrollbind(_Bool check);
DLLEXPORT void check_scrollbind(linenr_T topline_diff, long leftcol_diff);
DLLEXPORT _Bool find_decl(char_u *ptr, size_t len, _Bool locally, _Bool thisblock, int flags_arg);
DLLEXPORT void scroll_redraw(int up, long count);
DLLEXPORT void do_nv_ident(int c1, int c2);
DLLEXPORT _Bool get_visual_text(cmdarg_T *cap, char **pp, size_t *lenp);
DLLEXPORT void start_selection(void);
DLLEXPORT void may_start_select(int c);
DLLEXPORT _Bool unadjust_for_sel(void);
DLLEXPORT void set_cursor_for_append_to_line(void);
DLLEXPORT void normal_cmd(oparg_T *oap, _Bool toplevel);
#include "nvim/func_attr.h"
