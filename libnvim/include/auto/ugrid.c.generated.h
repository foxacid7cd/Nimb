#define DEFINE_FUNC_ATTRIBUTES
#include "nvim/func_attr.h"
#undef DEFINE_FUNC_ATTRIBUTES
static void clear_region(UGrid *grid, int top, int bot, int left, int right, sattr_T attr);
static void destroy_cells(UGrid *grid);
#include "nvim/func_attr.h"
