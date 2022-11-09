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
DLLEXPORT int u_save_cursor(void);
DLLEXPORT int u_save(linenr_T top, linenr_T bot);
DLLEXPORT int u_savesub(linenr_T lnum);
DLLEXPORT int u_inssub(linenr_T lnum);
DLLEXPORT int u_savedel(linenr_T lnum, long nlines);
DLLEXPORT _Bool undo_allowed(buf_T *buf);
DLLEXPORT int u_savecommon(buf_T *buf, linenr_T top, linenr_T bot, linenr_T newbot, int reload);
DLLEXPORT void u_compute_hash(buf_T *buf, char_u *hash);
DLLEXPORT char *u_get_undo_file_name(const char *const buf_ffname, const _Bool reading) FUNC_ATTR_WARN_UNUSED_RESULT;
DLLEXPORT void u_write_undo(const char *const name, const _Bool forceit, buf_T *const buf, char_u *const hash) FUNC_ATTR_NONNULL_ARG(3, 4);
DLLEXPORT void u_read_undo(char *name, const char_u *hash, const char_u *orig_name FUNC_ATTR_UNUSED) FUNC_ATTR_NONNULL_ARG(2);
DLLEXPORT void u_undo(int count);
DLLEXPORT void u_redo(int count);
DLLEXPORT _Bool u_undo_and_forget(int count, _Bool do_buf_event);
DLLEXPORT void undo_time(long step, _Bool sec, _Bool file, _Bool absolute);
DLLEXPORT void undo_fmt_time(char_u *buf, size_t buflen, time_t tt);
DLLEXPORT void u_sync(_Bool force);
DLLEXPORT void ex_undolist(exarg_T *eap);
DLLEXPORT void ex_undojoin(exarg_T *eap);
DLLEXPORT void u_unchanged(buf_T *buf);
DLLEXPORT void u_find_first_changed(void);
DLLEXPORT void u_update_save_nr(buf_T *buf);
DLLEXPORT void u_clearall(buf_T *buf);
DLLEXPORT void u_saveline(linenr_T lnum);
DLLEXPORT void u_clearline(void);
DLLEXPORT void u_undoline(void);
DLLEXPORT void u_blockfree(buf_T *buf);
DLLEXPORT _Bool bufIsChanged(buf_T *buf) FUNC_ATTR_NONNULL_ALL FUNC_ATTR_WARN_UNUSED_RESULT;
DLLEXPORT _Bool anyBufIsChanged(void) FUNC_ATTR_WARN_UNUSED_RESULT;
DLLEXPORT _Bool curbufIsChanged(void) FUNC_ATTR_WARN_UNUSED_RESULT;
DLLEXPORT list_T *u_eval_tree(const u_header_T *const first_uhp) FUNC_ATTR_WARN_UNUSED_RESULT FUNC_ATTR_NONNULL_RET;
DLLEXPORT u_header_T *u_force_get_undo_header(buf_T *buf);
#include "nvim/func_attr.h"
