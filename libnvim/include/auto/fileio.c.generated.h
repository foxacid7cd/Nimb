#define DEFINE_FUNC_ATTRIBUTES
#include "nvim/func_attr.h"
#undef DEFINE_FUNC_ATTRIBUTES
static linenr_T readfile_linenr(linenr_T linecnt, char_u *p, const char_u *endp);
static char *next_fenc(char **pp, _Bool *alloced) FUNC_ATTR_NONNULL_ALL FUNC_ATTR_NONNULL_RET;
static char_u *readfile_charconvert(char_u *fname, char_u *fenc, int *fdp);
static void check_marks_read(void);
static int set_rw_fname(char_u *fname, char_u *sfname);
static void add_quoted_fname(char *const ret_buf, const size_t buf_len, const buf_T *const buf, const char *fname) FUNC_ATTR_NONNULL_ARG(1);
static _Bool msg_add_fileformat(int eol_type);
static void msg_add_eol(void);
static int check_mtime(buf_T *buf, FileInfo *file_info);
static _Bool time_differs(const FileInfo *file_info, long mtime, long mtime_ns) FUNC_ATTR_CONST;
static int buf_write_bytes(struct bw_info *ip);
static _Bool ucs2bytes(unsigned c, char_u **pp, int flags) FUNC_ATTR_NONNULL_ALL;
static _Bool need_conversion(const char *fenc) FUNC_ATTR_NONNULL_ALL FUNC_ATTR_WARN_UNUSED_RESULT;
static int get_fio_flags(const char_u *name);
static char_u *check_for_bom(const char_u *p, long size, int *lenp, int flags);
static int make_bom(char_u *buf, char_u *name);
static int move_lines(buf_T *frombuf, buf_T *tobuf);
static void vim_mktempdir(void);
static _Bool vim_settempdir(char *tempdir);
#include "nvim/func_attr.h"
