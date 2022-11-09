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
DLLEXPORT void highlight_init(void);
DLLEXPORT _Bool highlight_use_hlstate(void);
DLLEXPORT void ui_send_all_hls(UI *ui);
DLLEXPORT int hl_get_syn_attr(int ns_id, int idx, HlAttrs at_en);
DLLEXPORT void ns_hl_def(NS ns_id, int hl_id, HlAttrs attrs, int link_id, Dict(highlight) *dict);
DLLEXPORT int ns_get_hl(NS *ns_hl, int hl_id, _Bool link, _Bool nodefault);
DLLEXPORT _Bool hl_check_ns(void);
DLLEXPORT _Bool win_check_ns_hl(win_T *wp);
DLLEXPORT int hl_get_ui_attr(int ns_id, int idx, int final_id, _Bool optional);
DLLEXPORT void update_window_hl(win_T *wp, _Bool invalid);
DLLEXPORT void update_ns_hl(int ns_id);
DLLEXPORT int win_bg_attr(win_T *wp);
DLLEXPORT int hl_get_underline(void);
DLLEXPORT int hl_get_term_attr(HlAttrs *aep);
DLLEXPORT void clear_hl_tables(_Bool reinit);
DLLEXPORT void hl_invalidate_blends(void);
DLLEXPORT int hl_combine_attr(int char_attr, int prim_attr);
DLLEXPORT int hl_blend_attrs(int back_attr, int front_attr, _Bool *through);
DLLEXPORT HlAttrs syn_attr2entry(int attr);
DLLEXPORT Dictionary hl_get_attr_by_id(Integer attr_id, Boolean rgb, Arena *arena, Error *err);
DLLEXPORT void hlattrs2dict(Dictionary *dict, HlAttrs ae, _Bool use_rgb);
DLLEXPORT HlAttrs dict2hlattrs(Dict(highlight) *dict, _Bool use_rgb, int *link_id, Error *err);
DLLEXPORT int object_to_color(Object val, char *key, _Bool rgb, Error *err);
DLLEXPORT Array hl_inspect(int attr);
#include "nvim/func_attr.h"
