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
DLLEXPORT int highlight_num_groups(void);
DLLEXPORT char_u *highlight_group_name(int id);
DLLEXPORT int highlight_link_id(int id);
DLLEXPORT void syn_init_cmdline_highlight(_Bool reset, _Bool init);
DLLEXPORT void init_highlight(_Bool both, _Bool reset);
DLLEXPORT int load_colors(char_u *name);
DLLEXPORT int lookup_color(const int idx, const _Bool foreground, TriState *const boldp);
DLLEXPORT void set_hl_group(int id, HlAttrs attrs, Dict(highlight) *dict, int link_id);
DLLEXPORT void do_highlight(const char *line, const _Bool forceit, const _Bool init) FUNC_ATTR_NONNULL_ALL;
DLLEXPORT void restore_cterm_colors(void);
DLLEXPORT Dictionary get_global_hl_defs(Arena *arena);
DLLEXPORT const char *highlight_has_attr(const int id, const int flag, const int modec) FUNC_ATTR_WARN_UNUSED_RESULT FUNC_ATTR_PURE;
DLLEXPORT const char *highlight_color(const int id, const char *const what, const int modec) FUNC_ATTR_WARN_UNUSED_RESULT FUNC_ATTR_NONNULL_ALL;
DLLEXPORT _Bool syn_list_header(const _Bool did_header, const int outlen, const int id, _Bool force_newline);
DLLEXPORT int syn_name2id(const char *name) FUNC_ATTR_NONNULL_ALL;
DLLEXPORT int syn_name2id_len(const char *name, size_t len) FUNC_ATTR_NONNULL_ALL;
DLLEXPORT int syn_name2attr(const char_u *name) FUNC_ATTR_NONNULL_ALL;
DLLEXPORT int highlight_exists(const char *name);
DLLEXPORT char_u *syn_id2name(int id);
DLLEXPORT int syn_check_group(const char *name, size_t len);
DLLEXPORT int syn_id2attr(int hl_id);
DLLEXPORT int syn_ns_id2attr(int ns_id, int hl_id, _Bool optional);
DLLEXPORT int syn_get_final_id(int hl_id);
DLLEXPORT int syn_ns_get_final_id(int *ns_id, int hl_id);
DLLEXPORT void highlight_attr_set_all(void);
DLLEXPORT void highlight_changed(void);
DLLEXPORT void set_context_in_highlight_cmd(expand_T *xp, const char *arg);
DLLEXPORT const char *get_highlight_name(expand_T *const xp, int idx) FUNC_ATTR_WARN_UNUSED_RESULT;
DLLEXPORT const char *get_highlight_name_ext(expand_T *xp, int idx, _Bool skip_cleared) FUNC_ATTR_WARN_UNUSED_RESULT;
DLLEXPORT RgbValue name_to_color(const char *name, int *idx);
DLLEXPORT const char *coloridx_to_name(int idx, int val, char hexbuf[8]);
DLLEXPORT int name_to_ctermcolor(const char *name);
#include "nvim/func_attr.h"
