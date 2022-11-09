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
DLLEXPORT void ins_ctrl_x(void);
DLLEXPORT _Bool ctrl_x_mode_none(void) FUNC_ATTR_PURE;
DLLEXPORT _Bool ctrl_x_mode_normal(void) FUNC_ATTR_PURE;
DLLEXPORT _Bool ctrl_x_mode_scroll(void) FUNC_ATTR_PURE;
DLLEXPORT _Bool ctrl_x_mode_whole_line(void) FUNC_ATTR_PURE;
DLLEXPORT _Bool ctrl_x_mode_files(void) FUNC_ATTR_PURE;
DLLEXPORT _Bool ctrl_x_mode_tags(void) FUNC_ATTR_PURE;
DLLEXPORT _Bool ctrl_x_mode_path_patterns(void) FUNC_ATTR_PURE;
DLLEXPORT _Bool ctrl_x_mode_path_defines(void) FUNC_ATTR_PURE;
DLLEXPORT _Bool ctrl_x_mode_dictionary(void) FUNC_ATTR_PURE;
DLLEXPORT _Bool ctrl_x_mode_thesaurus(void) FUNC_ATTR_PURE;
DLLEXPORT _Bool ctrl_x_mode_cmdline(void) FUNC_ATTR_PURE;
DLLEXPORT _Bool ctrl_x_mode_function(void) FUNC_ATTR_PURE;
DLLEXPORT _Bool ctrl_x_mode_omni(void) FUNC_ATTR_PURE;
DLLEXPORT _Bool ctrl_x_mode_spell(void) FUNC_ATTR_PURE;
DLLEXPORT _Bool ctrl_x_mode_line_or_eval(void) FUNC_ATTR_PURE;
DLLEXPORT _Bool ctrl_x_mode_not_default(void) FUNC_ATTR_PURE;
DLLEXPORT _Bool ctrl_x_mode_not_defined_yet(void) FUNC_ATTR_PURE;
DLLEXPORT _Bool compl_status_adding(void);
DLLEXPORT _Bool compl_status_sol(void);
DLLEXPORT _Bool compl_status_local(void);
DLLEXPORT void compl_status_clear(void);
DLLEXPORT _Bool check_compl_option(_Bool dict_opt);
DLLEXPORT _Bool vim_is_ctrl_x_key(int c) FUNC_ATTR_WARN_UNUSED_RESULT;
DLLEXPORT _Bool ins_compl_accept_char(int c) FUNC_ATTR_PURE FUNC_ATTR_WARN_UNUSED_RESULT;
DLLEXPORT int ins_compl_add_infercase(char_u *str_arg, int len, _Bool icase, char_u *fname, Direction dir, _Bool cont_s_ipos) FUNC_ATTR_NONNULL_ARG(1);
DLLEXPORT _Bool ins_compl_has_shown_match(void);
DLLEXPORT _Bool ins_compl_long_shown_match(void);
DLLEXPORT void completeopt_was_set(void);
DLLEXPORT _Bool pum_wanted(void) FUNC_ATTR_PURE FUNC_ATTR_WARN_UNUSED_RESULT;
DLLEXPORT void ins_compl_show_pum(void);
DLLEXPORT char_u *find_word_start(char_u *ptr) FUNC_ATTR_PURE;
DLLEXPORT char_u *find_word_end(char_u *ptr) FUNC_ATTR_PURE;
DLLEXPORT void ins_compl_clear(void);
DLLEXPORT _Bool ins_compl_active(void) FUNC_ATTR_PURE;
DLLEXPORT _Bool ins_compl_used_match(void);
DLLEXPORT void ins_compl_init_get_longest(void);
DLLEXPORT _Bool ins_compl_interrupted(void);
DLLEXPORT _Bool ins_compl_enter_selects(void);
DLLEXPORT colnr_T ins_compl_col(void);
DLLEXPORT int ins_compl_len(void);
DLLEXPORT int ins_compl_bs(void);
DLLEXPORT void ins_compl_addleader(int c);
DLLEXPORT void ins_compl_addfrommatch(void);
DLLEXPORT _Bool ins_compl_prep(int c);
DLLEXPORT int set_completefunc_option(void);
DLLEXPORT void set_buflocal_cfu_callback(buf_T *buf);
DLLEXPORT int set_omnifunc_option(void);
DLLEXPORT void set_buflocal_ofu_callback(buf_T *buf);
DLLEXPORT int set_thesaurusfunc_option(void);
DLLEXPORT _Bool set_ref_in_insexpand_funcs(int copyID);
DLLEXPORT void f_complete(typval_T *argvars, typval_T *rettv, EvalFuncData fptr);
DLLEXPORT void f_complete_add(typval_T *argvars, typval_T *rettv, EvalFuncData fptr);
DLLEXPORT void f_complete_check(typval_T *argvars, typval_T *rettv, EvalFuncData fptr);
DLLEXPORT void f_complete_info(typval_T *argvars, typval_T *rettv, EvalFuncData fptr);
DLLEXPORT void ins_compl_delete(void);
DLLEXPORT void ins_compl_insert(_Bool in_compl_func);
DLLEXPORT void ins_compl_check_keys(int frequency, _Bool in_compl_func);
DLLEXPORT int ins_complete(int c, _Bool enable_pum);
#include "nvim/func_attr.h"
