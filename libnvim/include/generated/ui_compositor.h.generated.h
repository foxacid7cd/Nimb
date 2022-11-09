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
DLLEXPORT void ui_comp_init(void);
DLLEXPORT void ui_comp_free_all_mem(void);
DLLEXPORT void ui_comp_syn_init(void);
DLLEXPORT void ui_comp_attach(UI *ui);
DLLEXPORT void ui_comp_detach(UI *ui);
DLLEXPORT _Bool ui_comp_should_draw(void);
DLLEXPORT _Bool ui_comp_put_grid(ScreenGrid *grid, int row, int col, int height, int width, _Bool valid, _Bool on_top);
DLLEXPORT void ui_comp_remove_grid(ScreenGrid *grid);
DLLEXPORT _Bool ui_comp_set_grid(handle_T handle);
DLLEXPORT ScreenGrid *ui_comp_mouse_focus(int row, int col);
DLLEXPORT ScreenGrid *ui_comp_get_grid_at_coord(int row, int col);
DLLEXPORT void ui_comp_compose_grid(ScreenGrid *grid);
DLLEXPORT _Bool ui_comp_set_screen_valid(_Bool valid);
DLLEXPORT void free_ui_event_callback(UIEventCallback *event_cb);
DLLEXPORT void ui_comp_add_cb(uint32_t ns_id, LuaRef cb, _Bool *ext_widgets);
DLLEXPORT void ui_comp_remove_cb(uint32_t ns_id);
#include "nvim/func_attr.h"
