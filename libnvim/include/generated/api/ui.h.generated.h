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
DLLEXPORT void remote_ui_disconnect(uint64_t channel_id);
DLLEXPORT void remote_ui_wait_for_attach(void);
DLLEXPORT void nvim_ui_attach(uint64_t channel_id, Integer width, Integer height, Dictionary options, Error *err) FUNC_API_SINCE(1) FUNC_API_REMOTE_ONLY;
DLLEXPORT void ui_attach(uint64_t channel_id, Integer width, Integer height, Boolean enable_rgb, Error *err) FUNC_API_DEPRECATED_SINCE(1);
DLLEXPORT void nvim_ui_detach(uint64_t channel_id, Error *err) FUNC_API_SINCE(1) FUNC_API_REMOTE_ONLY;
DLLEXPORT void nvim_ui_try_resize(uint64_t channel_id, Integer width, Integer height, Error *err) FUNC_API_SINCE(1) FUNC_API_REMOTE_ONLY;
DLLEXPORT void nvim_ui_set_option(uint64_t channel_id, String name, Object value, Error *error) FUNC_API_SINCE(1) FUNC_API_REMOTE_ONLY;
DLLEXPORT void nvim_ui_try_resize_grid(uint64_t channel_id, Integer grid, Integer width, Integer height, Error *err) FUNC_API_SINCE(6) FUNC_API_REMOTE_ONLY;
DLLEXPORT void nvim_ui_pum_set_height(uint64_t channel_id, Integer height, Error *err) FUNC_API_SINCE(6) FUNC_API_REMOTE_ONLY;
DLLEXPORT void nvim_ui_pum_set_bounds(uint64_t channel_id, Float width, Float height, Float row, Float col, Error *err) FUNC_API_SINCE(7) FUNC_API_REMOTE_ONLY;
#include "nvim/func_attr.h"
