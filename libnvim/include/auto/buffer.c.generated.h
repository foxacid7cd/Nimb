#define DEFINE_FUNC_ATTRIBUTES
#include "nvim/func_attr.h"
#undef DEFINE_FUNC_ATTRIBUTES
static int read_buffer(int read_stdin, exarg_T *eap, int flags);
static _Bool can_unload_buffer(buf_T *buf);
static void free_buffer(buf_T *buf);
static void clear_wininfo(buf_T *buf);
static void free_buffer_stuff(buf_T *buf, int free_flags);
static int empty_curbuf(int close_others, int forceit, int action);
static inline void buf_init_changedtick(buf_T *const buf) FUNC_ATTR_ALWAYS_INLINE FUNC_ATTR_NONNULL_ALL;
static buf_T *buflist_findname_file_id(char *ffname, FileID *file_id, _Bool file_id_valid) FUNC_ATTR_PURE;
static int buf_time_compare(const void *s1, const void *s2);
static char *buflist_match(regmatch_T *rmp, buf_T *buf, _Bool ignore_case);
static char *fname_match(regmatch_T *rmp, char *name, _Bool ignore_case);
static _Bool wininfo_other_tab_diff(wininfo_T *wip) FUNC_ATTR_PURE FUNC_ATTR_WARN_UNUSED_RESULT FUNC_ATTR_NONNULL_ALL;
static wininfo_T *find_wininfo(buf_T *buf, _Bool need_options, _Bool skip_diff_buffer) FUNC_ATTR_NONNULL_ALL FUNC_ATTR_PURE;
static _Bool otherfile_buf(buf_T *buf, char *ffname, FileID *file_id_p, _Bool file_id_valid) FUNC_ATTR_PURE FUNC_ATTR_WARN_UNUSED_RESULT;
static _Bool buf_same_file_id(buf_T *buf, FileID *file_id) FUNC_ATTR_PURE FUNC_ATTR_WARN_UNUSED_RESULT FUNC_ATTR_NONNULL_ALL;
static _Bool value_change(char *str, char **last) FUNC_ATTR_WARN_UNUSED_RESULT;
static int chk_modeline(linenr_T lnum, int flags);
static _Bool bt_nofileread(const buf_T *const buf) FUNC_ATTR_PURE FUNC_ATTR_WARN_UNUSED_RESULT;
static int buf_signcols_inner(buf_T *buf, int maximum);
#include "nvim/func_attr.h"
