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
DLLEXPORT void filemess(buf_T *buf, char *name, char *s, int attr);
DLLEXPORT int readfile(char *fname, char *sfname, linenr_T from, linenr_T lines_to_skip, linenr_T lines_to_read, exarg_T *eap, int flags, _Bool silent);
DLLEXPORT _Bool is_dev_fd_file(char *fname) FUNC_ATTR_NONNULL_ALL FUNC_ATTR_WARN_UNUSED_RESULT;
DLLEXPORT void prep_exarg(exarg_T *eap, const buf_T *buf) FUNC_ATTR_NONNULL_ALL;
DLLEXPORT void set_file_options(int set_options, exarg_T *eap);
DLLEXPORT void set_forced_fenc(exarg_T *eap);
DLLEXPORT char *new_file_message(void);
DLLEXPORT int buf_write(buf_T *buf, char *fname, char *sfname, linenr_T start, linenr_T end, exarg_T *eap, int append, int forceit, int reset_changed, int filtering);
DLLEXPORT void msg_add_lines(int insert_space, long lnum, off_T nchars);
DLLEXPORT void shorten_buf_fname(buf_T *buf, char_u *dirname, int force);
DLLEXPORT void shorten_fnames(int force);
DLLEXPORT char *modname(const char *fname, const char *ext, _Bool prepend_dot) FUNC_ATTR_NONNULL_ARG(2);
DLLEXPORT _Bool vim_fgets(char_u *buf, int size, FILE *fp) FUNC_ATTR_NONNULL_ALL;
DLLEXPORT int get2c(FILE *fd);
DLLEXPORT int get3c(FILE *fd);
DLLEXPORT int get4c(FILE *fd);
DLLEXPORT time_t get8ctime(FILE *fd);
DLLEXPORT char *read_string(FILE *fd, size_t cnt);
DLLEXPORT _Bool put_bytes(FILE *fd, uintmax_t number, size_t len);
DLLEXPORT int put_time(FILE *fd, time_t time_);
DLLEXPORT int vim_rename(const char *from, const char *to) FUNC_ATTR_NONNULL_ALL;
DLLEXPORT int check_timestamps(int focus);
DLLEXPORT int buf_check_timestamp(buf_T *buf) FUNC_ATTR_NONNULL_ALL;
DLLEXPORT void buf_reload(buf_T *buf, int orig_mode, _Bool reload_options);
DLLEXPORT void buf_store_file_info(buf_T *buf, FileInfo *file_info) FUNC_ATTR_NONNULL_ALL;
DLLEXPORT void write_lnum_adjust(linenr_T offset);
DLLEXPORT int readdir_core(garray_T *gap, const char *path, void *context, CheckItem checkitem) FUNC_ATTR_NONNULL_ARG(1, 2);
DLLEXPORT int delete_recursive(const char *name) FUNC_ATTR_NONNULL_ALL;
DLLEXPORT void vim_deltempdir(void);
DLLEXPORT char *vim_gettempdir(void);
DLLEXPORT char *vim_tempname(void);
DLLEXPORT _Bool match_file_pat(char *pattern, regprog_T **prog, char *fname, char *sfname, char *tail, int allow_dirs);
DLLEXPORT _Bool match_file_list(char_u *list, char_u *sfname, char_u *ffname) FUNC_ATTR_WARN_UNUSED_RESULT FUNC_ATTR_NONNULL_ARG(1, 3);
DLLEXPORT char *file_pat_to_reg_pat(const char *pat, const char *pat_end, char *allow_dirs, int no_bslash) FUNC_ATTR_NONNULL_ARG(1);
DLLEXPORT long read_eintr(int fd, void *buf, size_t bufsize);
DLLEXPORT long write_eintr(int fd, void *buf, size_t bufsize);
#include "nvim/func_attr.h"
