#define DEFINE_FUNC_ATTRIBUTES
#include "nvim/func_attr.h"
#undef DEFINE_FUNC_ATTRIBUTES
static void source_callback(char *fname, void *cookie);
static void push_path(RuntimeSearchPath *search_path, Map_String_handle_T *rtp_used, char *entry, _Bool after);
static void expand_rtp_entry(RuntimeSearchPath *search_path, Map_String_handle_T *rtp_used, char *entry, _Bool after);
static void expand_pack_entry(RuntimeSearchPath *search_path, Map_String_handle_T *rtp_used, CharVec *after_path, char *pack_entry, size_t pack_entry_len);
static _Bool path_is_after(char *buf, size_t buflen);
static void source_all_matches(char *pat);
static int add_pack_dir_to_rtp(char *fname, _Bool is_pack);
static int load_pack_plugin(_Bool opt, char *fname);
static void add_pack_plugin(_Bool opt, char *fname, void *cookie);
static void add_start_pack_plugin(char *fname, void *cookie);
static void add_opt_pack_plugin(char *fname, void *cookie);
static _Bool pack_has_entries(char *buf);
static void add_pack_start_dir(char *fname, void *cookie);
static char *strcpy_comma_escaped(char *dest, const char *src, const size_t len) FUNC_ATTR_NONNULL_ALL FUNC_ATTR_WARN_UNUSED_RESULT;
static inline size_t compute_double_env_sep_len(const char *const val, const size_t common_suf_len, const size_t single_suf_len) FUNC_ATTR_WARN_UNUSED_RESULT FUNC_ATTR_PURE;
static inline char *add_env_sep_dirs(char *dest, const char *const val, const char *const suf1, const size_t len1, const char *const suf2, const size_t len2, const _Bool forward) FUNC_ATTR_WARN_UNUSED_RESULT FUNC_ATTR_NONNULL_RET FUNC_ATTR_NONNULL_ARG(1);
static inline char *add_dir(char *dest, const char *const dir, const size_t dir_len, const XDGVarType type, const char *const suf1, const size_t len1, const char *const suf2, const size_t len2) FUNC_ATTR_NONNULL_RET FUNC_ATTR_NONNULL_ARG(1) FUNC_ATTR_WARN_UNUSED_RESULT;
static void cmd_source(char *fname, exarg_T *eap);
static FILE *fopen_noinh_readbin(char *filename);
static _Bool concat_continued_line(garray_T *const ga, const int init_growsize, const char *const p, size_t len) FUNC_ATTR_NONNULL_ALL;
static char *get_str_line(int c, void *cookie, int indent, _Bool do_concat);
static int source_using_linegetter(void *cookie, LineGetter fgetline, const char *traceback_name);
static void cmd_source_buffer(const exarg_T *const eap) FUNC_ATTR_NONNULL_ALL;
static char *get_one_sourceline(struct source_cookie *sp);
#include "nvim/func_attr.h"
