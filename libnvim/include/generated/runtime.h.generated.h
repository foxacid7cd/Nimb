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
DLLEXPORT void estack_init(void);
DLLEXPORT estack_T *estack_push(etype_T type, char *name, linenr_T lnum);
DLLEXPORT void estack_push_ufunc(ufunc_T *ufunc, linenr_T lnum);
DLLEXPORT void estack_pop(void);
DLLEXPORT char *estack_sfile(estack_arg_T which);
DLLEXPORT void runtime_init(void);
DLLEXPORT void ex_runtime(exarg_T *eap);
DLLEXPORT int do_in_path(char *path, char *name, int flags, DoInRuntimepathCB callback, void *cookie);
DLLEXPORT RuntimeSearchPath runtime_search_path_get_cached(int *ref) FUNC_ATTR_NONNULL_ALL;
DLLEXPORT RuntimeSearchPath copy_runtime_search_path(const RuntimeSearchPath src);
DLLEXPORT void runtime_search_path_unref(RuntimeSearchPath path, const int *ref) FUNC_ATTR_NONNULL_ALL;
DLLEXPORT int do_in_cached_path(char *name, int flags, DoInRuntimepathCB callback, void *cookie);
DLLEXPORT Array runtime_inspect(void);
DLLEXPORT ArrayOf(String) runtime_get_named(_Bool lua, Array pat, _Bool all);
DLLEXPORT ArrayOf(String) runtime_get_named_thread(_Bool lua, Array pat, _Bool all);
DLLEXPORT ArrayOf(String) runtime_get_named_common(_Bool lua, Array pat, _Bool all, RuntimeSearchPath path, char *buf, size_t buf_len);
DLLEXPORT int do_in_path_and_pp(char *path, char *name, int flags, DoInRuntimepathCB callback, void *cookie);
DLLEXPORT RuntimeSearchPath runtime_search_path_build(void);
DLLEXPORT void runtime_search_path_invalidate(void);
DLLEXPORT void runtime_search_path_free(RuntimeSearchPath path);
DLLEXPORT void runtime_search_path_validate(void);
DLLEXPORT int do_in_runtimepath(char *name, int flags, DoInRuntimepathCB callback, void *cookie);
DLLEXPORT int source_runtime(char *name, int flags);
DLLEXPORT int source_in_path(char *path, char *name, int flags);
DLLEXPORT void add_pack_start_dirs(void);
DLLEXPORT void load_start_packages(void);
DLLEXPORT void ex_packloadall(exarg_T *eap);
DLLEXPORT void load_plugins(void);
DLLEXPORT void ex_packadd(exarg_T *eap);
DLLEXPORT int ExpandRTDir(char *pat, int flags, int *num_file, char ***file, char *dirnames[]);
DLLEXPORT int ExpandPackAddDir(char *pat, int *num_file, char ***file);
DLLEXPORT char *get_lib_dir(void);
DLLEXPORT char *runtimepath_default(_Bool clean_arg);
DLLEXPORT void ex_source(exarg_T *eap);
DLLEXPORT void ex_options(exarg_T *eap);
DLLEXPORT linenr_T *source_breakpoint(void *cookie);
DLLEXPORT int *source_dbg_tick(void *cookie);
DLLEXPORT int source_level(void *cookie) FUNC_ATTR_PURE;
DLLEXPORT scriptitem_T *new_script_item(char *const name, scid_T *const sid_out);
DLLEXPORT int do_source_str(const char *cmd, const char *traceback_name);
DLLEXPORT int do_source(char *fname, int check_other, int is_vimrc);
DLLEXPORT scriptitem_T *get_current_script_id(char **fnamep, sctx_T *ret_sctx);
DLLEXPORT void ex_scriptnames(exarg_T *eap);
DLLEXPORT char *get_scriptname(LastSet last_set, _Bool *should_free);
DLLEXPORT linenr_T get_sourced_lnum(LineGetter fgetline, void *cookie) FUNC_ATTR_PURE;
DLLEXPORT char *getsourceline(int c, void *cookie, int indent, _Bool do_concat);
DLLEXPORT void ex_scriptencoding(exarg_T *eap);
DLLEXPORT void ex_finish(exarg_T *eap);
DLLEXPORT void do_finish(exarg_T *eap, int reanimate);
DLLEXPORT _Bool source_finished(LineGetter fgetline, void *cookie);
#include "nvim/func_attr.h"
