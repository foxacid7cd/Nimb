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
DLLEXPORT void bufhl_add_hl_pos_offset(buf_T *buf, int src_id, int hl_id, lpos_T pos_start, lpos_T pos_end, colnr_T offset);
DLLEXPORT void decor_redraw(buf_T *buf, int row1, int row2, Decoration *decor);
DLLEXPORT void decor_remove(buf_T *buf, int row, int row2, Decoration *decor);
DLLEXPORT void decor_free(Decoration *decor);
DLLEXPORT void decor_state_free(DecorState *state);
DLLEXPORT void clear_virttext(VirtText *text);
DLLEXPORT Decoration *decor_find_virttext(buf_T *buf, int row, uint64_t ns_id);
DLLEXPORT _Bool decor_redraw_reset(buf_T *buf, DecorState *state);
DLLEXPORT Decoration get_decor(mtkey_t mark);
DLLEXPORT _Bool decor_redraw_start(buf_T *buf, int top_row, DecorState *state);
DLLEXPORT _Bool decor_redraw_line(buf_T *buf, int row, DecorState *state);
DLLEXPORT int decor_redraw_col(buf_T *buf, int col, int win_col, _Bool hidden, DecorState *state);
DLLEXPORT void decor_redraw_signs(buf_T *buf, int row, int *num_signs, SignTextAttrs sattrs[], HlPriAttr *num_attrs, HlPriAttr *line_attrs, HlPriAttr *cul_attrs);
DLLEXPORT int decor_signcols(buf_T *buf, DecorState *state, int row, int end_row, int max);
DLLEXPORT void decor_redraw_end(DecorState *state);
DLLEXPORT _Bool decor_redraw_eol(buf_T *buf, DecorState *state, int *eol_attr, int eol_col);
DLLEXPORT void decor_add_ephemeral(int start_row, int start_col, int end_row, int end_col, Decoration *decor, uint64_t ns_id, uint64_t mark_id);
DLLEXPORT int decor_virt_lines(win_T *wp, linenr_T lnum, VirtLines *lines);
#include "nvim/func_attr.h"
