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
DLLEXPORT void aupat_del_for_event_and_group(event_T event, int group);
DLLEXPORT AutoPat *au_get_autopat_for_event(event_T event) FUNC_ATTR_PURE;
DLLEXPORT void aubuflocal_remove(buf_T *buf);
DLLEXPORT int augroup_add(char *name);
DLLEXPORT void augroup_del(char *name, _Bool stupid_legacy_mode);
DLLEXPORT int augroup_find(const char *name) FUNC_ATTR_PURE FUNC_ATTR_WARN_UNUSED_RESULT;
DLLEXPORT char *augroup_name(int group);
DLLEXPORT _Bool augroup_exists(const char *name) FUNC_ATTR_PURE FUNC_ATTR_WARN_UNUSED_RESULT;
DLLEXPORT void do_augroup(char *arg, int del_group);
DLLEXPORT event_T event_name2nr(const char *start, char **end);
DLLEXPORT const char *event_nr2name(event_T event) FUNC_ATTR_NONNULL_RET FUNC_ATTR_WARN_UNUSED_RESULT FUNC_ATTR_CONST;
DLLEXPORT int check_ei(void);
DLLEXPORT char *au_event_disable(char *what);
DLLEXPORT void au_event_restore(char *old_ei);
DLLEXPORT void do_autocmd(exarg_T *eap, char *arg_in, int forceit);
DLLEXPORT void do_all_autocmd_events(char *pat, _Bool once, int nested, char *cmd, _Bool delete, int group);
DLLEXPORT int do_autocmd_event(event_T event, char *pat, _Bool once, int nested, char *cmd, _Bool delete, int group) FUNC_ATTR_NONNULL_ALL;
DLLEXPORT int autocmd_register(int64_t id, event_T event, char *pat, int patlen, int group, _Bool once, _Bool nested, char *desc, AucmdExecutable aucmd);
DLLEXPORT size_t aucmd_pattern_length(char *pat) FUNC_ATTR_PURE;
DLLEXPORT char *aucmd_next_pattern(char *pat, size_t patlen) FUNC_ATTR_PURE;
DLLEXPORT int do_doautocmd(char *arg_start, _Bool do_msg, _Bool *did_something);
DLLEXPORT void ex_doautoall(exarg_T *eap);
DLLEXPORT _Bool check_nomodeline(char **argp) FUNC_ATTR_NONNULL_ALL FUNC_ATTR_WARN_UNUSED_RESULT;
DLLEXPORT void aucmd_prepbuf(aco_save_T *aco, buf_T *buf);
DLLEXPORT void aucmd_restbuf(aco_save_T *aco);
DLLEXPORT _Bool apply_autocmds(event_T event, char *fname, char *fname_io, _Bool force, buf_T *buf);
DLLEXPORT _Bool apply_autocmds_exarg(event_T event, char *fname, char *fname_io, _Bool force, buf_T *buf, exarg_T *eap);
DLLEXPORT _Bool apply_autocmds_retval(event_T event, char *fname, char *fname_io, _Bool force, buf_T *buf, int *retval);
DLLEXPORT _Bool has_event(event_T event) FUNC_ATTR_PURE FUNC_ATTR_WARN_UNUSED_RESULT;
DLLEXPORT _Bool has_cursorhold(void) FUNC_ATTR_PURE FUNC_ATTR_WARN_UNUSED_RESULT;
DLLEXPORT _Bool trigger_cursorhold(void) FUNC_ATTR_PURE FUNC_ATTR_WARN_UNUSED_RESULT;
DLLEXPORT _Bool apply_autocmds_group(event_T event, char *fname, char *fname_io, _Bool force, int group, buf_T *buf, exarg_T *eap, Object *data);
DLLEXPORT void block_autocmds(void);
DLLEXPORT void unblock_autocmds(void);
DLLEXPORT _Bool is_autocmd_blocked(void) FUNC_ATTR_PURE FUNC_ATTR_WARN_UNUSED_RESULT;
DLLEXPORT void auto_next_pat(AutoPatCmd *apc, int stop_at_last);
DLLEXPORT char *getnextac(int c, void *cookie, int indent, _Bool do_concat);
DLLEXPORT _Bool has_autocmd(event_T event, char *sfname, buf_T *buf) FUNC_ATTR_WARN_UNUSED_RESULT;
DLLEXPORT char *expand_get_augroup_name(expand_T *xp, int idx);
DLLEXPORT char *set_context_in_autocmd(expand_T *xp, char *arg, int doautocmd);
DLLEXPORT char *expand_get_event_name(expand_T *xp, int idx);
DLLEXPORT _Bool autocmd_supported(const char *const event) FUNC_ATTR_PURE FUNC_ATTR_WARN_UNUSED_RESULT;
DLLEXPORT _Bool au_exists(const char *const arg) FUNC_ATTR_WARN_UNUSED_RESULT;
DLLEXPORT _Bool aupat_is_buflocal(char *pat, int patlen) FUNC_ATTR_PURE;
DLLEXPORT int aupat_get_buflocal_nr(char *pat, int patlen);
DLLEXPORT void aupat_normalize_buflocal_pat(char *dest, char *pat, int patlen, int buflocal_nr);
DLLEXPORT int autocmd_delete_event(int group, event_T event, char *pat) FUNC_ATTR_NONNULL_ALL;
DLLEXPORT _Bool autocmd_delete_id(int64_t id);
DLLEXPORT char *aucmd_exec_to_string(AutoCmd *ac, AucmdExecutable acc) FUNC_ATTR_PURE;
DLLEXPORT void aucmd_exec_free(AucmdExecutable *acc);
DLLEXPORT AucmdExecutable aucmd_exec_copy(AucmdExecutable src);
DLLEXPORT _Bool aucmd_exec_is_deleted(AucmdExecutable acc) FUNC_ATTR_PURE;
DLLEXPORT _Bool au_event_is_empty(event_T event) FUNC_ATTR_PURE;
DLLEXPORT void do_autocmd_uienter(uint64_t chanid, _Bool attached);
DLLEXPORT void autocmd_schedule_focusgained(_Bool gained);
DLLEXPORT void init_default_autocmds(void);
#include "nvim/func_attr.h"
