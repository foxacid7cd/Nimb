#define DEFINE_FUNC_ATTRIBUTES
#include "nvim/func_attr.h"
#undef DEFINE_FUNC_ATTRIBUTES
static void pum_compute_size(void);
static _Bool pum_set_selected(int n, int repeat);
static void pum_position_at_mouse(int min_width);
static void pum_select_mouse_pos(void);
static void pum_execute_menu(vimmenu_T *menu, int mode);
#include "nvim/func_attr.h"
