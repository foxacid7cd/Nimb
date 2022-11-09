#define DEFINE_FUNC_ATTRIBUTES
#include "nvim/func_attr.h"
#undef DEFINE_FUNC_ATTRIBUTES
static void mpack_w2(char **b, uint32_t v);
static void mpack_w4(char **b, uint32_t v);
static void mpack_uint(char **buf, uint32_t val);
static void mpack_array(char **buf, uint32_t len);
static char *mpack_array_dyn16(char **buf);
static void mpack_str(char **buf, const char *str);
static void ui_set_option(UI *ui, _Bool init, String name, Object value, Error *error);
static void flush_event(UIData *data);
static inline int write_cb(void *vdata, const char *buf, size_t len);
static _Bool prepare_call(UI *ui, const char *name);
static void push_call(UI *ui, const char *name, Array args);
static void remote_ui_grid_clear(UI *ui, Integer grid);
static void remote_ui_grid_resize(UI *ui, Integer grid, Integer width, Integer height);
static void remote_ui_grid_scroll(UI *ui, Integer grid, Integer top, Integer bot, Integer left, Integer right, Integer rows, Integer cols);
static void remote_ui_default_colors_set(UI *ui, Integer rgb_fg, Integer rgb_bg, Integer rgb_sp, Integer cterm_fg, Integer cterm_bg);
static void remote_ui_hl_attr_define(UI *ui, Integer id, HlAttrs rgb_attrs, HlAttrs cterm_attrs, Array info);
static void remote_ui_highlight_set(UI *ui, int id);
static void remote_ui_grid_cursor_goto(UI *ui, Integer grid, Integer row, Integer col);
static void remote_ui_cursor_goto(UI *ui, Integer row, Integer col);
static void remote_ui_put(UI *ui, const char *cell);
static void remote_ui_raw_line(UI *ui, Integer grid, Integer row, Integer startcol, Integer endcol, Integer clearcol, Integer clearattr, LineFlags flags, const schar_T *chunk, const sattr_T *attrs);
static void remote_ui_flush_buf(UI *ui);
static void remote_ui_flush(UI *ui);
static Array translate_contents(UI *ui, Array contents, Arena *arena);
static Array translate_firstarg(UI *ui, Array args, Arena *arena);
static void remote_ui_event(UI *ui, char *name, Array args);
static void remote_ui_inspect(UI *ui, Dictionary *info);
#include "nvim/func_attr.h"
