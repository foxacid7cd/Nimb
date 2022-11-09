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
DLLEXPORT void ui_client_init(uint64_t chan);
DLLEXPORT UIClientHandler ui_client_get_redraw_handler(const char *name, size_t name_len, Error *error);
DLLEXPORT Object handle_ui_client_redraw(uint64_t channel_id, Array args, Arena *arena, Error *error);
DLLEXPORT void ui_client_execute(uint64_t chan) FUNC_ATTR_NORETURN;
DLLEXPORT void ui_client_event_grid_resize(Array args);
DLLEXPORT void ui_client_event_grid_line(Array args) FUNC_ATTR_NORETURN;
DLLEXPORT void ui_client_event_raw_line(GridLineEvent *g);
#include "nvim/func_attr.h"
