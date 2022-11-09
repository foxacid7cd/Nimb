#define DEFINE_FUNC_ATTRIBUTES
#include "nvim/func_attr.h"
#undef DEFINE_FUNC_ATTRIBUTES
static void ui_thread_run(void *data);
static void ui_bridge_stop(UI *b);
static void ui_bridge_stop_event(void **argv);
static void ui_bridge_hl_attr_define(UI *ui, Integer id, HlAttrs attrs, HlAttrs cterm_attrs, Array info);
static void ui_bridge_hl_attr_define_event(void **argv);
static void ui_bridge_raw_line_event(void **argv);
static void ui_bridge_raw_line(UI *ui, Integer grid, Integer row, Integer startcol, Integer endcol, Integer clearcol, Integer clearattr, LineFlags flags, const schar_T *chunk, const sattr_T *attrs);
static void ui_bridge_suspend(UI *b);
static void ui_bridge_suspend_event(void **argv);
static void ui_bridge_option_set(UI *ui, String name, Object value);
static void ui_bridge_option_set_event(void **argv);
static void ui_bridge_inspect(UI *ui, Dictionary *info);
#include "nvim/func_attr.h"
