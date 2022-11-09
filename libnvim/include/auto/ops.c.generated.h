#define DEFINE_FUNC_ATTRIBUTES
#include "nvim/func_attr.h"
#undef DEFINE_FUNC_ATTRIBUTES
static void shift_block(oparg_T *oap, int amount);
static void block_insert(oparg_T *oap, char *s, int b_insert, struct block_def *bdp);
static _Bool is_append_register(int regname);
static inline _Bool is_literal_register(int regname) FUNC_ATTR_CONST;
static void set_yreg_additional_data(yankreg_T *reg, dict_T *additional_data) FUNC_ATTR_NONNULL_ARG(1);
static int stuff_yank(int regname, char *p);
static char_u *execreg_line_continuation(char **lines, size_t *idx);
static void put_reedit_in_typebuf(int silent);
static int put_in_typebuf(char_u *s, _Bool esc, _Bool colon, int silent);
static void shift_delete_registers(_Bool y_append);
static void mb_adjust_opend(oparg_T *oap);
static inline void pbyte(pos_T lp, int c);
static void replace_character(int c);
static int op_replace(oparg_T *oap, int c);
static int swapchars(int op_type, pos_T *pos, int length) FUNC_ATTR_NONNULL_ALL;
static void op_yank_reg(oparg_T *oap, _Bool message, yankreg_T *reg, _Bool append);
static void yank_copy_line(yankreg_T *reg, struct block_def *bd, size_t y_idx, _Bool exclude_trailing_space) FUNC_ATTR_NONNULL_ALL;
static void do_autocmd_textyankpost(oparg_T *oap, yankreg_T *reg) FUNC_ATTR_NONNULL_ALL;
static void dis_msg(const char *p, _Bool skip_esc) FUNC_ATTR_NONNULL_ALL;
static _Bool reset_lbr(void);
static void restore_lbr(_Bool lbr_saved);
static void block_prep(oparg_T *oap, struct block_def *bdp, linenr_T lnum, _Bool is_del);
static void *get_reg_wrap_one_line(char *s, int flags);
static yankreg_T *init_write_reg(int name, yankreg_T **old_y_previous, _Bool must_append);
static void finish_write_reg(int name, yankreg_T *reg, yankreg_T *old_y_previous);
static void str_to_reg(yankreg_T *y_ptr, MotionType yank_type, const char *str, size_t len, colnr_T blocklen, _Bool str_list) FUNC_ATTR_NONNULL_ALL;
static varnumber_T line_count_info(char_u *line, varnumber_T *wc, varnumber_T *cc, varnumber_T limit, int eol_size);
static void op_colon(oparg_T *oap);
static void op_function(const oparg_T *oap) FUNC_ATTR_NONNULL_ALL;
static void get_op_vcol(oparg_T *oap, colnr_T redo_VIsual_vcol, _Bool initial);
static yankreg_T *adjust_clipboard_name(int *name, _Bool quiet, _Bool writing);
static _Bool get_clipboard(int name, yankreg_T **target, _Bool quiet);
static void set_clipboard(int name, yankreg_T *reg);
static inline _Bool reg_empty(const yankreg_T *const reg) FUNC_ATTR_PURE;
#include "nvim/func_attr.h"
