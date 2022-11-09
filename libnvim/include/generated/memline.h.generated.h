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
DLLEXPORT int ml_open(buf_T *buf);
DLLEXPORT void ml_setname(buf_T *buf);
DLLEXPORT void ml_open_files(void);
DLLEXPORT void ml_open_file(buf_T *buf);
DLLEXPORT void check_need_swap(_Bool newfile);
DLLEXPORT void ml_close(buf_T *buf, int del_file);
DLLEXPORT void ml_close_all(_Bool del_file);
DLLEXPORT void ml_close_notmod(void);
DLLEXPORT void ml_timestamp(buf_T *buf);
DLLEXPORT void ml_recover(_Bool checkext);
DLLEXPORT int recover_names(char_u *fname, int list, int nr, char **fname_out);
DLLEXPORT char *make_percent_swname(const char *dir, const char *name) FUNC_ATTR_NONNULL_ARG(1);
DLLEXPORT void get_b0_dict(const char *fname, dict_T *d);
DLLEXPORT void ml_sync_all(int check_file, int check_char, _Bool do_fsync);
DLLEXPORT void ml_preserve(buf_T *buf, int message, _Bool do_fsync);
DLLEXPORT char *ml_get(linenr_T lnum);
DLLEXPORT char_u *ml_get_pos(const pos_T *pos) FUNC_ATTR_NONNULL_ALL;
DLLEXPORT int gchar_pos(pos_T *pos) FUNC_ATTR_NONNULL_ARG(1);
DLLEXPORT char *ml_get_buf(buf_T *buf, linenr_T lnum, _Bool will_change) FUNC_ATTR_NONNULL_ALL;
DLLEXPORT int ml_line_alloced(void);
DLLEXPORT int ml_append(linenr_T lnum, char *line, colnr_T len, _Bool newfile);
DLLEXPORT int ml_append_buf(buf_T *buf, linenr_T lnum, char_u *line, colnr_T len, _Bool newfile) FUNC_ATTR_NONNULL_ARG(1);
DLLEXPORT void ml_add_deleted_len(char *ptr, ssize_t len);
DLLEXPORT void ml_add_deleted_len_buf(buf_T *buf, char_u *ptr, ssize_t len);
DLLEXPORT int ml_replace(linenr_T lnum, char *line, _Bool copy);
DLLEXPORT int ml_replace_buf(buf_T *buf, linenr_T lnum, char *line, _Bool copy);
DLLEXPORT int ml_delete(linenr_T lnum, _Bool message);
DLLEXPORT void ml_setmarked(linenr_T lnum);
DLLEXPORT linenr_T ml_firstmarked(void);
DLLEXPORT void ml_clearmarked(void);
DLLEXPORT size_t ml_flush_deleted_bytes(buf_T *buf, size_t *codepoints, size_t *codeunits);
DLLEXPORT int resolve_symlink(const char *fname, char *buf);
DLLEXPORT char_u *makeswapname(char_u *fname, char_u *ffname, buf_T *buf, char_u *dir_name);
DLLEXPORT char *get_file_in_dir(char *fname, char *dname);
DLLEXPORT void ml_setflags(buf_T *buf);
DLLEXPORT long ml_find_line_or_offset(buf_T *buf, linenr_T lnum, long *offp, _Bool no_ff);
DLLEXPORT void goto_byte(long cnt);
DLLEXPORT int inc(pos_T *lp);
DLLEXPORT int incl(pos_T *lp);
DLLEXPORT int dec(pos_T *lp);
DLLEXPORT int decl(pos_T *lp);
#include "nvim/func_attr.h"
