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
DLLEXPORT yankreg_T *get_y_previous(void);
DLLEXPORT void set_y_previous(yankreg_T *yreg);
DLLEXPORT int get_op_type(int char1, int char2);
DLLEXPORT int op_on_lines(int op);
DLLEXPORT int op_is_change(int op);
DLLEXPORT int get_op_char(int optype);
DLLEXPORT int get_extra_op_char(int optype);
DLLEXPORT void op_shift(oparg_T *oap, int curs_top, int amount);
DLLEXPORT void shift_line(int left, int round, int amount, int call_changed_bytes);
DLLEXPORT void op_reindent(oparg_T *oap, Indenter how);
DLLEXPORT int get_expr_register(void);
DLLEXPORT void set_expr_line(char *new_line);
DLLEXPORT char *get_expr_line(void);
DLLEXPORT char *get_expr_line_src(void);
DLLEXPORT _Bool valid_yank_reg(int regname, _Bool writing);
DLLEXPORT yankreg_T *get_yank_register(int regname, int mode);
DLLEXPORT yankreg_T *copy_register(int name) FUNC_ATTR_NONNULL_RET;
DLLEXPORT _Bool yank_register_mline(int regname);
DLLEXPORT int do_record(int c);
DLLEXPORT int do_execreg(int regname, int colon, int addcr, int silent);
DLLEXPORT int insert_reg(int regname, _Bool literally_arg);
DLLEXPORT _Bool get_spec_reg(int regname, char **argp, _Bool *allocated, _Bool errmsg);
DLLEXPORT _Bool cmdline_paste_reg(int regname, _Bool literally_arg, _Bool remcr);
DLLEXPORT int op_delete(oparg_T *oap);
DLLEXPORT void op_tilde(oparg_T *oap);
DLLEXPORT _Bool swapchar(int op_type, pos_T *pos) FUNC_ATTR_NONNULL_ARG(2);
DLLEXPORT void op_insert(oparg_T *oap, long count1);
DLLEXPORT int op_change(oparg_T *oap);
DLLEXPORT void free_register(yankreg_T *reg) FUNC_ATTR_NONNULL_ALL;
DLLEXPORT _Bool op_yank(oparg_T *oap, _Bool message) FUNC_ATTR_NONNULL_ALL;
DLLEXPORT void do_put(int regname, yankreg_T *reg, int dir, long count, int flags);
DLLEXPORT void adjust_cursor_eol(void);
DLLEXPORT int preprocs_left(void);
DLLEXPORT int get_register_name(int num);
DLLEXPORT int get_unname_register(void);
DLLEXPORT void ex_display(exarg_T *eap);
DLLEXPORT char *skip_comment(char *line, _Bool process, _Bool include_space, _Bool *is_comment);
DLLEXPORT int do_join(size_t count, int insert_space, int save_undo, int use_formatoptions, _Bool setmark);
DLLEXPORT void op_addsub(oparg_T *oap, linenr_T Prenum1, _Bool g_cmd);
DLLEXPORT int do_addsub(int op_type, pos_T *pos, int length, linenr_T Prenum1);
DLLEXPORT MotionType get_reg_type(int regname, colnr_T *reg_width);
DLLEXPORT void format_reg_type(MotionType reg_type, colnr_T reg_width, char *buf, size_t buf_len) FUNC_ATTR_NONNULL_ALL;
DLLEXPORT void *get_reg_contents(int regname, int flags);
DLLEXPORT void write_reg_contents(int name, const char *str, ssize_t len, int must_append);
DLLEXPORT void write_reg_contents_lst(int name, char **strings, _Bool must_append, MotionType yank_type, colnr_T block_len);
DLLEXPORT void write_reg_contents_ex(int name, const char *str, ssize_t len, _Bool must_append, MotionType yank_type, colnr_T block_len);
DLLEXPORT void clear_oparg(oparg_T *oap);
DLLEXPORT void cursor_pos_info(dict_T *dict);
DLLEXPORT int set_operatorfunc_option(void);
DLLEXPORT _Bool set_ref_in_opfunc(int copyID);
DLLEXPORT void do_pending_operator(cmdarg_T *cap, int old_col, _Bool gui_yank);
DLLEXPORT int get_default_register_name(void);
DLLEXPORT _Bool prepare_yankreg_from_object(yankreg_T *reg, String regtype, size_t lines);
DLLEXPORT void finish_yankreg_from_object(yankreg_T *reg, _Bool clipboard_adjust);
DLLEXPORT void start_batch_changes(void);
DLLEXPORT void end_batch_changes(void);
DLLEXPORT int save_batch_count(void);
DLLEXPORT void restore_batch_count(int save_count);
DLLEXPORT const void *op_global_reg_iter(const void *const iter, char *const name, yankreg_T *const reg, _Bool *is_unnamed) FUNC_ATTR_NONNULL_ARG(2, 3, 4) FUNC_ATTR_WARN_UNUSED_RESULT;
DLLEXPORT const void *op_reg_iter(const void *const iter, const yankreg_T *const regs, char *const name, yankreg_T *const reg, _Bool *is_unnamed) FUNC_ATTR_NONNULL_ARG(3, 4, 5) FUNC_ATTR_WARN_UNUSED_RESULT;
DLLEXPORT size_t op_reg_amount(void) FUNC_ATTR_WARN_UNUSED_RESULT;
DLLEXPORT _Bool op_reg_set(const char name, const yankreg_T reg, _Bool is_unnamed);
DLLEXPORT const yankreg_T *op_reg_get(const char name);
DLLEXPORT _Bool op_reg_set_previous(const char name);
DLLEXPORT bcount_t get_region_bytecount(buf_T *buf, linenr_T start_lnum, linenr_T end_lnum, colnr_T start_col, colnr_T end_col);
#include "nvim/func_attr.h"
