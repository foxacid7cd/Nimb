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
DLLEXPORT mapblock_T *get_maphash_list(int state, int c);
DLLEXPORT mapblock_T *get_buf_maphash_list(int state, int c);
DLLEXPORT mapblock_T *get_maphash(int index, buf_T *buf) FUNC_ATTR_PURE;
DLLEXPORT int do_map(int maptype, char_u *arg, int mode, _Bool is_abbrev);
DLLEXPORT void map_clear_mode(buf_T *buf, int mode, _Bool local, _Bool abbr);
DLLEXPORT _Bool map_to_exists(const char *const str, const char *const modechars, const _Bool abbr) FUNC_ATTR_NONNULL_ALL FUNC_ATTR_WARN_UNUSED_RESULT FUNC_ATTR_PURE;
DLLEXPORT int map_to_exists_mode(const char *const rhs, const int mode, const _Bool abbr);
DLLEXPORT char_u *set_context_in_map_cmd(expand_T *xp, char *cmd, char_u *arg, _Bool forceit, _Bool isabbrev, _Bool isunmap, cmdidx_T cmdidx);
DLLEXPORT int ExpandMappings(regmatch_T *regmatch, int *num_file, char ***file);
DLLEXPORT _Bool check_abbr(int c, char_u *ptr, int col, int mincol);
DLLEXPORT char *eval_map_expr(mapblock_T *mp, int c);
DLLEXPORT int makemap(FILE *fd, buf_T *buf);
DLLEXPORT int put_escstr(FILE *fd, char_u *strstart, int what);
DLLEXPORT char_u *check_map(char_u *keys, int mode, int exact, int ign_mod, int abbr, mapblock_T **mp_ptr, int *local_ptr, int *rhs_lua);
DLLEXPORT void f_hasmapto(typval_T *argvars, typval_T *rettv, EvalFuncData fptr);
DLLEXPORT void f_mapset(typval_T *argvars, typval_T *rettv, EvalFuncData fptr);
DLLEXPORT void f_maparg(typval_T *argvars, typval_T *rettv, EvalFuncData fptr);
DLLEXPORT void f_mapcheck(typval_T *argvars, typval_T *rettv, EvalFuncData fptr);
DLLEXPORT void add_map(char *lhs, char *rhs, int mode, _Bool buffer);
DLLEXPORT int langmap_adjust_mb(int c);
DLLEXPORT void langmap_init(void);
DLLEXPORT void langmap_set(void);
DLLEXPORT void ex_abbreviate(exarg_T *eap);
DLLEXPORT void ex_map(exarg_T *eap);
DLLEXPORT void ex_unmap(exarg_T *eap);
DLLEXPORT void ex_mapclear(exarg_T *eap);
DLLEXPORT void ex_abclear(exarg_T *eap);
DLLEXPORT void modify_keymap(uint64_t channel_id, Buffer buffer, _Bool is_unmap, String mode, String lhs, String rhs, Dict(keymap) *opts, Error *err);
DLLEXPORT ArrayOf(Dictionary) keymap_array(String mode, buf_T *buf);
#include "nvim/func_attr.h"
