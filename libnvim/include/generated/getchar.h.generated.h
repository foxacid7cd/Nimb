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
DLLEXPORT void free_buff(buffheader_T *buf);
DLLEXPORT char_u *get_recorded(void);
DLLEXPORT char_u *get_inserted(void);
DLLEXPORT int stuff_empty(void) FUNC_ATTR_PURE;
DLLEXPORT int readbuf1_empty(void) FUNC_ATTR_PURE;
DLLEXPORT void typeahead_noflush(int c);
DLLEXPORT void flush_buffers(flush_buffers_T flush_typeahead);
DLLEXPORT void beep_flush(void);
DLLEXPORT void ResetRedobuff(void);
DLLEXPORT void CancelRedo(void);
DLLEXPORT void saveRedobuff(save_redo_T *save_redo);
DLLEXPORT void restoreRedobuff(save_redo_T *save_redo);
DLLEXPORT void AppendToRedobuff(const char *s);
DLLEXPORT void AppendToRedobuffLit(const char *str, int len);
DLLEXPORT void AppendCharToRedobuff(int c);
DLLEXPORT void AppendNumberToRedobuff(long n);
DLLEXPORT void stuffReadbuff(const char *s);
DLLEXPORT void stuffRedoReadbuff(const char *s);
DLLEXPORT void stuffReadbuffLen(const char *s, long len);
DLLEXPORT void stuffReadbuffSpec(const char *s);
DLLEXPORT void stuffcharReadbuff(int c);
DLLEXPORT void stuffnumReadbuff(long n);
DLLEXPORT void stuffescaped(const char *arg, _Bool literally);
DLLEXPORT int start_redo(long count, _Bool old_redo);
DLLEXPORT int start_redo_ins(void);
DLLEXPORT void stop_redo_ins(void);
DLLEXPORT _Bool noremap_keys(void);
DLLEXPORT int ins_typebuf(char *str, int noremap, int offset, _Bool nottyped, _Bool silent);
DLLEXPORT int ins_char_typebuf(int c, int modifiers);
DLLEXPORT _Bool typebuf_changed(int tb_change_cnt) FUNC_ATTR_PURE;
DLLEXPORT int typebuf_typed(void) FUNC_ATTR_PURE;
DLLEXPORT int typebuf_maplen(void) FUNC_ATTR_PURE;
DLLEXPORT void del_typebuf(int len, int offset);
DLLEXPORT void ungetchars(int len);
DLLEXPORT void may_sync_undo(void);
DLLEXPORT void alloc_typebuf(void);
DLLEXPORT void free_typebuf(void);
DLLEXPORT void save_typebuf(void);
DLLEXPORT void save_typeahead(tasave_T *tp);
DLLEXPORT void restore_typeahead(tasave_T *tp);
DLLEXPORT void openscript(char *name, _Bool directly);
DLLEXPORT int using_script(void) FUNC_ATTR_PURE;
DLLEXPORT void before_blocking(void);
DLLEXPORT int merge_modifiers(int c_arg, int *modifiers);
DLLEXPORT int vgetc(void);
DLLEXPORT int safe_vgetc(void);
DLLEXPORT int plain_vgetc(void);
DLLEXPORT int vpeekc(void);
DLLEXPORT int vpeekc_any(void);
DLLEXPORT int char_avail(void);
DLLEXPORT void f_getchar(typval_T *argvars, typval_T *rettv, EvalFuncData fptr);
DLLEXPORT void f_getcharstr(typval_T *argvars, typval_T *rettv, EvalFuncData fptr);
DLLEXPORT void f_getcharmod(typval_T *argvars, typval_T *rettv, EvalFuncData fptr);
DLLEXPORT void vungetc(int c);
DLLEXPORT void check_end_reg_executing(_Bool advance);
DLLEXPORT int inchar(char_u *buf, int maxlen, long wait_time);
DLLEXPORT int fix_input_buffer(char_u *buf, int len) FUNC_ATTR_NONNULL_ALL;
DLLEXPORT char *getcmdkeycmd(int promptc, void *cookie, int indent, _Bool do_concat);
DLLEXPORT _Bool map_execute_lua(void);
#include "nvim/func_attr.h"
